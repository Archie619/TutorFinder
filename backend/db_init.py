import os
import pyodbc

connect_str = (
    'DSN=MSSQLServerDatabase;'
    f'UID={os.environ["TF_UID"]};'
    f'PWD={os.environ["TF_PWD"]};'
    'TrustServerCertificate=yes'
)

db_con = pyodbc.connect(connect_str)
cursor = db_con.cursor()
