import sys
import os
import pandas as pd
import matplotlib.pyplot as plt
from sqlalchemy import create_engine, text

# Add parent dir to path to find config if needed, or just load env manually
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../..')))

from backend.database import SQLALCHEMY_DATABASE_URL

def generate_chart():
    print("Connecting to database...")
    engine = create_engine(SQLALCHEMY_DATABASE_URL)
    
    # User's Query
    sql_query = """
    with Jml_date as(
        select extract(day from p.appointmentTime) as tanggal
        from patientqueue p 
    )
    select tanggal , count(tanggal) as jml_antrian
    from Jml_date
    group by tanggal
    order by tanggal asc
    """
    
    print("Executing query...")
    try:
        with engine.connect() as connection:
            df = pd.read_sql(text(sql_query), connection)
            
        print("Query Result:")
        print(df)
        
        if df.empty:
            print("No data found to plot.")
            return

        # Plotting
        plt.figure(figsize=(10, 6))
        plt.bar(df['tanggal'].astype(str), df['jml_antrian'], color='skyblue')
        plt.xlabel('Tanggal (Day of Month)')
        plt.ylabel('Jumlah Antrian')
        plt.title('Jumlah Antrian per Tanggal')
        plt.grid(axis='y', linestyle='--', alpha=0.7)
        
        output_path = os.path.join(os.path.dirname(__file__), 'queue_chart.png')
        plt.savefig(output_path)
        print(f"Chart saved to: {output_path}")
        
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    generate_chart()
