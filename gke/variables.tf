variable "projectid" {
  type        = string
  description = "The project id to work in"
}

variable "region" {
  type        = string
  description = "The region to deploy everything in"
}

variable "location" {
  type        = string
  description = "The location to deploy everything in. Should be within the region"
}
