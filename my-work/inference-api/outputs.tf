# ------------------
#    OUTPUTS
# ------------------

output "api_id" {
  description = "The ID of the created inference API"
  value       = azurerm_api_management_api.inference_api.id
}

output "api_name" {
  description = "The name of the created inference API"
  value       = azurerm_api_management_api.inference_api.name
}

output "api_path" {
  description = "The path of the inference API"
  value       = azurerm_api_management_api.inference_api.path
}

output "backend_ids" {
  description = "The IDs of the created backend services"
  value       = azurerm_api_management_backend.inference_backend[*].id
}

output "backend_names" {
  description = "The names of the created backend services"
  value       = azurerm_api_management_backend.inference_backend[*].name
}

output "backend_pool_id" {
  description = "The ID of the backend pool (if created)"
  value       = length(azurerm_api_management_backend.backend_pool) > 0 ? azurerm_api_management_backend.backend_pool[0].id : null
}

output "backend_pool_name" {
  description = "The name of the backend pool (if created)"
  value       = length(azurerm_api_management_backend.backend_pool) > 0 ? azurerm_api_management_backend.backend_pool[0].name : null
}

output "diagnostics_monitor_id" {
  description = "The ID of the Azure Monitor diagnostics configuration (if created)"
  value       = length(azurerm_api_management_api_diagnostic.api_diagnostics_monitor) > 0 ? azurerm_api_management_api_diagnostic.api_diagnostics_monitor[0].id : null
}

output "diagnostics_appinsights_id" {
  description = "The ID of the Application Insights diagnostics configuration (if created)"
  value       = length(azurerm_api_management_api_diagnostic.api_diagnostics_appinsights) > 0 ? azurerm_api_management_api_diagnostic.api_diagnostics_appinsights[0].id : null
}