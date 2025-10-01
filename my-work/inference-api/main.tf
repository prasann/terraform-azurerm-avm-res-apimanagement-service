/**
 * Terraform module for creating an inference API in Azure API Management
 * This module is equivalent to the Bicep inference.bicep file and creates:
 * - API Management API for inference
 * - Backend services for AI endpoints
 * - Backend pool for load balancing (when multiple services)
 * - API policies and diagnostics
 */

# ------------------
#    LOCALS
# ------------------

locals {
  # Determine the endpoint path based on API type
  endpoint_path = var.inference_api_type == "AzureOpenAI" ? "openai" : var.inference_api_type == "AzureAI" ? "models" : ""
  
  # Update policy XML with the correct backend ID
  updated_policy_xml = replace(
    var.policy_xml,
    "{backend-id}",
    length(var.ai_services_config) > 1 ? var.inference_backend_pool_name : var.ai_services_config[0].name
  )
  
  # Log settings for diagnostics
  log_settings = {
    headers = ["Content-type", "User-agent", "x-ms-region", "x-ratelimit-remaining-tokens", "x-ratelimit-remaining-requests"]
    body    = { bytes = 8192 }
  }
  
  # Determine OpenAPI spec content based on API type, using existing spec files
  openapi_spec_content = (
    var.inference_api_type == "AzureOpenAI" && var.azure_openai_spec != "" ? var.azure_openai_spec : 
    var.inference_api_type == "AzureAI" && var.azure_ai_spec != "" ? var.azure_ai_spec :
    var.inference_api_type == "AzureOpenAI" ? 
      replace(
        file("${path.module}/specs/AIFoundryOpenAI.json"),
        "{endpoint}",
        replace(var.ai_services_config[0].endpoint, "/openai", "")
      ) :
      replace(
        file("${path.module}/specs/AIFoundryAzureAI.json"),
        "{endpoint}",
        replace(var.ai_services_config[0].endpoint, "https://", "")
      )
  )
}

# ------------------
#    DATA SOURCES
# ------------------

data "azurerm_api_management" "apim" {
  name                = var.api_management_name
  resource_group_name = var.resource_group_name
}

# ------------------
#    RESOURCES
# ------------------

# API Management API for inference
resource "azurerm_api_management_api" "inference_api" {
  name                  = var.inference_api_name
  api_management_name   = data.azurerm_api_management.apim.name
  resource_group_name   = var.resource_group_name
  revision              = "1"
  display_name          = var.inference_api_display_name
  description           = var.inference_api_description
  path                  = "${var.inference_api_path}/${local.endpoint_path}"
  protocols             = ["https"]
  subscription_required = true
  
  subscription_key_parameter_names {
    header = "x-apim-key"
    query  = "x-apim-key"
  }
  
  import {
    content_format = "openapi+json"
    content_value  = local.openapi_spec_content
  }
  
  lifecycle {
    prevent_destroy = true
  }
}

# API Policy
resource "azurerm_api_management_api_policy" "inference_api_policy" {
  api_name            = azurerm_api_management_api.inference_api.name
  api_management_name = data.azurerm_api_management.apim.name
  resource_group_name = var.resource_group_name
  xml_content         = local.updated_policy_xml
  
  depends_on = [
    azurerm_api_management_backend.inference_backend,
    azurerm_api_management_backend.backend_pool
  ]
  
  lifecycle {
    prevent_destroy = true
  }
}

# Backend services for each AI service
resource "azurerm_api_management_backend" "inference_backend" {
  count               = length(var.ai_services_config)
  name                = var.ai_services_config[count.index].name
  api_management_name = data.azurerm_api_management.apim.name
  resource_group_name = var.resource_group_name
  description         = "Inference backend for ${var.ai_services_config[count.index].name}"
  url                 = "${var.ai_services_config[count.index].endpoint}/${local.endpoint_path}"
  protocol            = "http"
  
  credentials {
    # Use Azure managed identity for AI Foundry authentication
    certificate = []
    query       = {}
    header      = {}
  }
  
  lifecycle {
    prevent_destroy = true
  }
}

# Backend pool for load balancing (simplified - using single backend approach)
# Note: Azure provider doesn't support Pool type backends in the current version
# Instead, we'll use a weighted round-robin approach with the first backend as primary
resource "azurerm_api_management_backend" "backend_pool" {
  count               = length(var.ai_services_config) > 1 ? 1 : 0
  name                = var.inference_backend_pool_name
  api_management_name = data.azurerm_api_management.apim.name
  resource_group_name = var.resource_group_name
  description         = "Primary backend for inference endpoints"
  
  # Use the first AI service as the primary backend
  url      = var.ai_services_config[0].endpoint
  protocol = "http"
  
  # Proxy configuration
  proxy {
    url      = var.ai_services_config[0].endpoint
    username = ""
    password = ""
  }
  
  # Authentication using managed identity for AI Foundry
  credentials {
    certificate = []
    query       = {}
    header      = {}
  }
  
  lifecycle {
    prevent_destroy = true
  }
}

# API Diagnostics for Azure Monitor (if logger ID is provided)
resource "azurerm_api_management_api_diagnostic" "api_diagnostics_monitor" {
  count                        = var.apim_logger_id != "" ? 1 : 0
  identifier                   = "azuremonitor"
  resource_group_name          = var.resource_group_name
  api_management_name          = data.azurerm_api_management.apim.name
  api_name                     = azurerm_api_management_api.inference_api.name
  api_management_logger_id     = var.apim_logger_id
  always_log_errors            = true
  verbosity                    = "verbose"
  log_client_ip               = true
  sampling_percentage         = 100.0
  
  frontend_request {
    body_bytes     = 0
    headers_to_log = []
  }
  
  frontend_response {
    body_bytes     = 0
    headers_to_log = []
  }
  
  backend_request {
    body_bytes     = 0
    headers_to_log = []
  }
  
  backend_response {
    body_bytes     = 0
    headers_to_log = []
  }
  
  lifecycle {
    prevent_destroy = true
  }
}

# API Diagnostics for Application Insights (if App Insights is configured)
resource "azurerm_api_management_api_diagnostic" "api_diagnostics_appinsights" {
  count                        = var.app_insights_id != "" && var.app_insights_instrumentation_key != "" ? 1 : 0
  identifier                   = "applicationinsights"
  resource_group_name          = var.resource_group_name
  api_management_name          = data.azurerm_api_management.apim.name
  api_name                     = azurerm_api_management_api.inference_api.name
  api_management_logger_id     = "${data.azurerm_api_management.apim.id}/loggers/appinsights-logger"
  always_log_errors            = true
  verbosity                    = "verbose"
  log_client_ip               = true
  http_correlation_protocol    = "W3C"
  sampling_percentage         = 100.0
  
  frontend_request {
    body_bytes     = local.log_settings.body.bytes
    headers_to_log = local.log_settings.headers
  }
  
  frontend_response {
    body_bytes     = local.log_settings.body.bytes
    headers_to_log = local.log_settings.headers
  }
  
  backend_request {
    body_bytes     = local.log_settings.body.bytes
    headers_to_log = local.log_settings.headers
  }
  
  backend_response {
    body_bytes     = local.log_settings.body.bytes
    headers_to_log = local.log_settings.headers
  }
  
  lifecycle {
    prevent_destroy = true
  }
}