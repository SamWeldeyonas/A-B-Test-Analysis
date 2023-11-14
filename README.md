# A-B-Test-Analysis

## Introduction 
GloBox - An online marketplace specializing in sourcing unique and high-quality products from around the world.
GloBox is primarily known amongst its customer base for boutique fashion items and high-end decor products. However, their food and drink offerings have grown tremendously in the last few months, and the company wants to bring awareness to this product category to increase revenue.


We are running an A/B test experiment to improve the homepage, and they need your help!

In this project, you will analyze the results of an A/B test and create a report of data-driven recommendations based on your findings.

Project Logistics
The project features three stages, each being one sprint: 

Extract the user-level aggregated dataset using SQL.
Analyze the A/B test results using statistical methods in spreadsheets and visualizations in Tableau.
Create a written report of the A/B test results and optionally record a video presentation.
Students who submit the project before the deadline(s) at the end of the unit will receive personalized feedback on their work.







The setup of the A/B test is as follows:

- The experiment is only being run on the mobile website.
- A user visits the GloBox main page and is randomly assigned to either the control or test group. This is the join date for the user.
- The page loads the banner if the user is assigned to the test group, and does not load the banner if the user is assigned to the control group.
- The user subsequently may or may not purchase products from the website. It could be on the same day they join the experiment, or days later. If they do make one or more purchases, this is considered a “conversion”.





Stakeholders

Your task is to analyze the results of the A/B test and provide a recommendation to your stakeholders about whether GloBox should launch the experience to all users. The group that you will be presenting to includes the following:

Growth Product & Engineering Team: This is the team that you work with at GloBox. The team is made up of a product manager, a user experience designer, an engineering manager and several software engineers, and you, the data analyst. The team develops features for the GloBox website that drive growth in users and revenue.
Leila Al-Farsi, Product Manager, Growth: Leila is the product manager for the Growth product and engineering team. Alongside Alejandro, she leads the Growth team by deciding their goals and projects, measuring their success against defined KPIs, and communicating results to other company leaders like Mei.
Alejandro Gonzalez, User Experience Designer, Growth: Alejandro is the designer for the Growth product and engineering team. He conducts user research and designed the experience that the A/B test is evaluating.
Mei Kim, Head of Marketing: Mei oversees the Marketing team, which works on targeting audiences with effective marketing campaigns to drive customers to the GloBox website. She collaborates frequently with Leila and Alejandro to design website experiences that will align well with the current marketing efforts.
Together, Leila, Alejandro, and Mei will decide whether or not to launch the experiment based on the results.




The Dataset
GloBox stores its data in a relational database and includes the following tables. 


You can find a description of each table and its columns below.
users: user demographic information
- id: the user ID
- country: ISO 3166 alpha-3 country code
- gender: the user's gender (M = male, F = female, O = other)
groups: user A/B test group assignment
- uid: the user ID
- group: the user’s test group
- join_dt: the date the user joined the test (visited the page)
- device: the device the user visited the page on (I = iOS, A = android)

activity: user purchase activity, containing 1 row per day that a user made a purchase
- uid: the user ID
- dt: date of purchase activity
- device: the device type the user purchased on (I = iOS, A = android)
- spent: the purchase amount in USD
