variable "project" {}
variable "region" {
  default = "europe-west1"
}
variable "zone" {
  default = "europe-west1-c"
}

variable "image_ai_player" {
  type = string
}
variable "image_ai_chatbot" {
  type = string
}
variable "image_ollama" {
  type = string
}
variable "image_recommendation" {
  type = string
}

variable "gitlab_username_player" {
  description = "GitLab username for registry access"
  type        = string
}

variable "gitlab_token_player" {
  description = "GitLab Personal Access Token or Deploy Token with read_registry scope"
  type        = string
  sensitive   = true
}

variable "gitlab_username_chatbot" {
  description = "GitLab username for registry access"
  type        = string
}

variable "gitlab_token_chatbot" {
  description = "GitLab Personal Access Token or Deploy Token with read_registry scope"
  type        = string
  sensitive   = true
}

variable "gitlab_username_ollama" {
  type = string
}

variable "gitlab_token_ollama" {
  type = string
  sensitive = true
}

variable "gitlab_username_recommendation" {
  type = string
}

variable "gitlab_token_recommendation" {
  type = string
  sensitive = true
}

variable "gemini_api_key" {
  type      = string
  sensitive = true
}

variable "api_key_iao_7" {
  type      = string
  sensitive = true
}

variable "api_key_iao_11" {
  type      = string
  sensitive = true
}

variable "api_key_iao_15" {
  type      = string
  sensitive = true
}

variable "api_key_iao_19" {
  type      = string
  sensitive = true
}

variable "api_key_iao_22" {
  type      = string
  sensitive = true
}

variable "api_key_ai_team" {
  type      = string
  sensitive = true
}
