terraform {
  required_providers {
    render = {
      source  = "renderinc/render"
      version = "0.1.0"
    }
  }
}

provider "render" {
  api_key = var.render_api_key
}

variable "render_api_key" {
  description = "API key para Render almacenada de forma segura"
  type        = string
}

resource "render_service" "crud_backend" {
  name   = "crud-backend-demo"
  type   = "web_service"
  repo   = "https://github.com/JuanBallesteros06/devops-practica-pipeline"
  env    = "docker"
  plan   = "starter"
  branch = "main"

  build_command = "docker build -t app ."
  start_command = "npm start"
  auto_deploy   = true
}
