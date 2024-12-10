variable "bucket_name" {
  type        = string
  description = "Nome do bucket na aws"
  default     = "prj-devops-2024-adriano"
}

variable "environment" {
  description = "Define o nome do ambiente, neste caso setado como default, mas poderiamos ter outros"
  default     = "dev"
}

variable "endereco_de_email" {
  description = "Envia um email disparado pela função lambida informando o status da persistência no banco de dados"
  default = "adrianoprogm@hotmail.com"
  
}

# Variáveis de configuração do RDS(Mysql)
variable "db_username" {
  default = "admin"
}

variable "db_password" {
  default = "DevOps2024" 
}

variable "db_name" {
  default = "devops_db"
}

# Levando em conta que é um ambiente de desenvolvimento, satisfaz as condiçẽs.
variable "db_instance_class" {
  default = "db.m5.large" 
}

variable "allocated_storage"{
     default = 20
}

variable "engine"{
   default =  "sqlserver-se"
  }        
  