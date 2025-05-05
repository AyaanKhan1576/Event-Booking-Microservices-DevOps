variable "key_pair_name" {
  description = "Name of the key pair to use for SSH access (must be created in AWS Console first)"
  type        = string
}

variable "db_password" {
  description = "Password for the database"
  type        = string
  default     = "minahil.ali117"
  sensitive   = true
}

variable "secret_key_booking" {
  description = "Secret key for booking service"
  type        = string
  default     = "123456798"
  sensitive   = true
}

variable "secret_key_user" {
  description = "Secret key for user service"
  type        = string
  default     = "123456789"
  sensitive   = true
}