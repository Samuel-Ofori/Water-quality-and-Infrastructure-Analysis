# Water-quality-and-Infrastructure-Analysis
This project focused on analyzing water quality and infrastructure.

Project Overview
The analysis is centered on:

Evaluating water sources based on pollution results
Identifying infrastructure needs for various water source types
Tracking employee data to assess improvement efforts
Generating recommendations for improvement (e.g., installing filters, diagnosing infrastructure issues, etc.)
Database Structure
The project uses the following tables:

visits: Contains information on visits to each water source, including queue times and assigned employees.
well_pollution: Tracks pollution results for well water sources.
water_source: Stores metadata on each water source, including type and population served.
location: Stores location-specific information, including town, province, and address.
Project_progress: Tracks improvement projects for each source, including status and comments.
Key Features
Project Tracking: Automatically updates improvement recommendations based on water quality results and queue times.
Employee Performance: Monitors employee performance by tracking discrepancies between auditor and surveyor assessments.
Infrastructure Recommendations: Generates specific infrastructure improvement actions based on data (e.g., installing additional taps for long queues).
How to Run the Project
Import the SQL files provided in the /sql directory.
Populate the database with sample data, following the instructions in data_loading.sql.
Execute the query files to generate views, track progress, and analyze data.
