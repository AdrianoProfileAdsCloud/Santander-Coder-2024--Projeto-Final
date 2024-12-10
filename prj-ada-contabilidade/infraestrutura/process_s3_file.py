import boto3
import os
import pymysql  # Biblioteca para conexão ao MySQL
import logging
from dotenv import load_dotenv

logger = logging.getLogger()
logger.setLevel(logging.INFO)


# Configurações
s3_client = boto3.client("s3")
sns_client = boto3.client("sns")

sns_topic_arn = os.getenv("SNS_TOPIC_ARN")
# Para evitar erros quando a variável não estiver configurada, estou adicionando o "127.0.0.1" como padrão
db_host = os.getenv("DB_HOST", "prj-devops-rds.cishrjnb8j7s.us-east-1.rds.amazonaws.com")  
db_name = os.getenv("DB_NAME")
db_user = os.getenv("DB_USER")
db_password = os.getenv("DB_PASSWORD")

logger.info(f"DB_HOST: {db_host}, DB_NAME: {db_name}, DB_USER: {db_user}")


def lambda_handler(event, context):
    for record in event["Records"]:
        bucket_name = record["s3"]["bucket"]["name"]
        file_key = record["s3"]["object"]["key"]

        try:
            # Baixar o arquivo do S3
            response = s3_client.get_object(Bucket=bucket_name, Key=file_key)
            content = response["Body"].read().decode("utf-8")
            line_count = len(content.splitlines())

            # Salvar no RDS
            save_to_rds(file_key, line_count)

            # Publicar mensagem no SNS
            message = f"Arquivo '{file_key}' processado com sucesso. Linhas: {line_count}."
            sns_client.publish(
                TopicArn=sns_topic_arn,
                Message=message,
                Subject="Processamento de Arquivo"
            )
        except Exception as e:
            logger.error(f"Ocorreu uma exception: {e}", exc_info=True)
            sns_client.publish(
                TopicArn=sns_topic_arn,
                Message=f"Erro ao processar o arquivo '{file_key}': {str(e)}",
                Subject="Erro no Processamento"
            )
            raise e

def save_to_rds(file_name, line_count):
    # Conectar ao banco de dados
    connection = pymysql.connect(
        host=db_host,
        user=db_user,
        password=db_password,
        database=db_name,
        connect_timeout=5
    )
    
    try:
        with connection.cursor() as cursor:
            # Criar a tabela se não existir
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS file_processing (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    file_name VARCHAR(255),
                    line_count INT,
                    processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            # Inserir os dados processados
            cursor.execute("""
                INSERT INTO file_processing (file_name, line_count)
                VALUES (%s, %s)
            """, (file_name, line_count))

        connection.commit()
    finally:
        connection.close()
