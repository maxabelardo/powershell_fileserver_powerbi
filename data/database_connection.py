import pyodbc
import psycopg2
import mysql.connector
import cx_Oracle
import json

class DatabaseConnection:
    def __init__(self, db_type, server, database, config_file=".\data\config.json"):
        self.db_type = db_type
        self.server = server
        self.database = database
        self.user = None
        self.password = None
        self.load_credentials(config_file)
        self.connection = None
        self.connect()

    def load_credentials(self, config_file):
        with open(config_file, 'r') as f:
            config = json.load(f)
            self.user = config.get("user")
            self.password = config.get("password")

    def connect(self):
        if self.db_type == 'SQLServer':
            connection_str = f'DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={self.server};DATABASE={self.database};UID={self.user};PWD={self.password}'
            self.connection = pyodbc.connect(connection_str)
        elif self.db_type == 'PostgreSQL':
            self.connection = psycopg2.connect(host=self.server, database=self.database, user=self.user, password=self.password)
        elif self.db_type == 'MySQL':
            self.connection = mysql.connector.connect(host=self.server, database=self.database, user=self.user, password=self.password)
        elif self.db_type == 'Oracle':
            self.connection = cx_Oracle.connect(self.user, self.password, self.server)

    def close(self):
        if self.connection:
            self.connection.close()
