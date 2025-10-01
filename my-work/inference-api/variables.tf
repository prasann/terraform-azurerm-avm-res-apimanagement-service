# ------------------
#    VARIABLES
# ------------------

variable "resource_group_name" {
  description = "The name of the resource group where APIM is deployed"
  type        = string
}

variable "api_management_name" {
  description = "The name of the API Management instance"
  type        = string
}

variable "apim_logger_id" {
  description = "The ID of the APIM Logger for Azure Monitor diagnostics"
  type        = string
  default     = ""
}

variable "app_insights_instrumentation_key" {
  description = "The instrumentation key for Application Insights"
  type        = string
  default     = ""
  sensitive   = true
}

variable "app_insights_id" {
  description = "The resource ID for Application Insights"
  type        = string
  default     = ""
}

variable "policy_xml" {
  description = "The XML content for the API policy. Use {backend-id} placeholder for backend reference"
  type        = string
}

variable "ai_services_config" {
  description = "Configuration array for AI Services"
  type = list(object({
    name     = string
    endpoint = string
    priority = optional(number)
    weight   = optional(number)
  }))
  default = []
}

variable "inference_api_name" {
  description = "The name of the Inference API in API Management"
  type        = string
  default     = "inference-api"
}

variable "inference_api_description" {
  description = "The description of the Inference API in API Management"
  type        = string
  default     = "Inferencing API"
}

variable "inference_api_display_name" {
  description = "The display name of the Inference API in API Management"
  type        = string
  default     = "Inference API"
}

variable "inference_backend_pool_name" {
  description = "The name of the Inference backend pool"
  type        = string
  default     = "inference-backend-pool"
}

variable "inference_api_type" {
  description = "The inference API type"
  type        = string
  default     = "AzureOpenAI"
  validation {
    condition     = contains(["AzureOpenAI", "AzureAI", "OpenAI"], var.inference_api_type)
    error_message = "The inference_api_type must be one of: AzureOpenAI, AzureAI, OpenAI."
  }
}

variable "inference_api_path" {
  description = "The path to the inference API in the APIM service"
  type        = string
  default     = "inference"
}

variable "configure_circuit_breaker" {
  description = "Whether to configure the circuit breaker for the inference backend"
  type        = bool
  default     = false
}

variable "azure_openai_spec" {
  description = "OpenAPI specification for Azure OpenAI endpoints"
  type        = string
  default     = ""
}

variable "azure_ai_spec" {
  description = "OpenAPI specification for Azure AI endpoints"
  type        = string
  default     = ""
}

variable "openai_spec" {
  description = "OpenAPI specification for OpenAI endpoints"
  type        = string
  default     = ""
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}