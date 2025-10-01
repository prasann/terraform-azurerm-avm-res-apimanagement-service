# Example: Using the Inference API Terraform Module

This example demonstrates how to use the inference API Terraform module to create an AI inference API in Azure API Management.

## Prerequisites

1. An existing Azure API Management instance
2. Azure AI services or Azure OpenAI resources
3. Appropriate permissions to create APIM resources

## Basic Usage

```hcl
# Example: Creating an inference API with Azure OpenAI backend
module "inference_api" {
  source = "./inference_api"

  # Required parameters
  resource_group_name  = "rg-example"
  api_management_name  = "apim-example"
  policy_xml          = file("${path.module}/policies/inference-policy.xml")
  
  # AI Services configuration
  ai_services_config = [
    {
      name     = "openai-east-us"
      endpoint = "https://myopenai-eastus.openai.azure.com/"
      priority = 1
      weight   = 50
    },
    {
      name     = "openai-west-us"
      endpoint = "https://myopenai-westus.openai.azure.com/"
      priority = 1
      weight   = 50
    }
  ]
  
  # API configuration
  inference_api_type         = "AzureOpenAI"
  inference_api_name         = "azure-openai-api"
  inference_api_display_name = "Azure OpenAI Inference API"
  inference_api_description  = "API for Azure OpenAI inference with load balancing"
  inference_api_path         = "ai"
  
  # OpenAPI specification
  azure_openai_spec = file("${path.module}/specs/AIFoundryOpenAI.json")
  
  # Circuit breaker (optional)
  configure_circuit_breaker = true
  
  # Diagnostics (optional)
  apim_logger_id                    = azurerm_api_management_logger.example.id
  app_insights_id                   = azurerm_application_insights.example.id
  app_insights_instrumentation_key = azurerm_application_insights.example.instrumentation_key
  
  tags = {
    Environment = "production"
    Team        = "ai-platform"
  }
}
```

## Example with Azure AI Foundry

```hcl
module "inference_api_foundry" {
  source = "./inference_api"

  resource_group_name  = "rg-example"
  api_management_name  = "apim-example"
  policy_xml          = file("${path.module}/policies/foundry-policy.xml")
  
  ai_services_config = [
    {
      name     = "foundry-model-gpt4"
      endpoint = "https://my-foundry.region.inference.ml.azure.com/"
    }
  ]
  
  inference_api_type         = "AzureAI"
  inference_api_name         = "foundry-inference-api"
  inference_api_display_name = "Azure AI Foundry API"
  inference_api_path         = "foundry"
  
  azure_ai_spec = file("${path.module}/specs/AIFoundryAzureAI.json")
}
```

## Sample Policy XML

Create a file `policies/inference-policy.xml` with content like:

```xml
<policies>
    <inbound>
        <base />
        <set-backend-service backend-id="{backend-id}" />
        <authentication-managed-identity resource="https://cognitiveservices.azure.com" />
        <set-header name="Content-Type" exists-action="override">
            <value>application/json</value>
        </set-header>
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
```

## Outputs

The module provides several outputs that can be used by other resources:

```hcl
# Reference the created API
output "inference_api_id" {
  value = module.inference_api.api_id
}

output "inference_api_path" {
  value = module.inference_api.api_path
}

# Reference backend services
output "backend_names" {
  value = module.inference_api.backend_names
}
```

## Integration with Existing APIM Module

If you're using this with the existing `api.tf` module pattern:

```hcl
# Your existing APIM setup
resource "azurerm_api_management" "apim_internal" {
  # ... existing configuration from api.tf
}

# Add the inference API
module "inference_api" {
  source = "./inference_api"
  
  resource_group_name  = azurerm_api_management.apim_internal.resource_group_name
  api_management_name  = azurerm_api_management.apim_internal.name
  policy_xml          = file("${path.module}/policies/inference-policy.xml")
  
  ai_services_config = var.ai_services_config
  
  # Use the same logger from your existing setup
  apim_logger_id = azurerm_api_management_logger.apim_logger.id
}

# Add to existing product
resource "azurerm_api_management_product_api" "inference_product" {
  api_name            = module.inference_api.api_name
  product_id          = azurerm_api_management_product.starter.product_id
  api_management_name = azurerm_api_management.apim_internal.name
  resource_group_name = azurerm_api_management.apim_internal.resource_group_name
}
```

## Required Variables for Integration

Add these to your `variables.tf`:

```hcl
variable "ai_services_config" {
  description = "Configuration for AI services"
  type = list(object({
    name     = string
    endpoint = string
    priority = optional(number)
    weight   = optional(number)
  }))
  default = []
}

variable "inference_policy_xml" {
  description = "Policy XML for the inference API"
  type        = string
  default     = ""
}
```