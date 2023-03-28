variable "default_tags" {
  type = map(string)
  default = {
    "env" = "terraform-myya"
  }
  description = "myyas variables description"
}

variable "public_subnet_count" {
  type        = number
  description = "public subnet count"
  default     = 2

}