# 📊 Layoffs Data Cleaning and Analysis
SQL-based project focused on cleaning and analyzing real-world layoffs data.


This project focuses primarily on **data cleaning** using SQL, with some light exploratory data analysis (EDA) to extract basic insights.

## 📁 Dataset Source
- [Layoffs 2022 Dataset on Kaggle](https://www.kaggle.com/datasets/swaptr/layoffs-2022)

## 📂 Files
- `layoffs.csv`: Raw dataset file
- `cleaned_layoffs_data.csv`: Final cleaned dataset
- `layoffs_data_cleaning.sql`: SQL script for cleaning the data
- `layoffs_eda.sql`: SQL script for basic exploratory data analysis

## 🧹 Description
- 🧽 Cleaned the dataset by:
  - Removing duplicates using window functions
  - Handling missing values (standardizing blanks and nulls)
  - Standardizing text formatting and date fields
  - Dropping irrelevant rows and columns
- 🧪 Light EDA was performed to explore patterns in layoffs by date, company, and industry

## 🛠️ Tool Used
- SQL
