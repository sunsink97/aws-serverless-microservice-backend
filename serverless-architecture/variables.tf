variable "environment" {
  default = "dev"
  type    = string
}

variable "python_version" {

  default = "python3.12"
  type    = string
}

variable "project_name" {

  default = "microservice-architecture"
  type = string
}

variable "lambda_initial_spec" { //   <--- value ideally taken from terraform enterprise. will make changing lambda spec easier without alternating code and just need to change var on tf enterise + apply.

  default = {
    "memory_size"      = 512
    "timeout"          = 10
    "ephemeral_storage" = {
      size = 512  
    }
  }
}