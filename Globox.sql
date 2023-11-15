{
  "metadata": {
    "language_info": {
      "codemirror_mode": "sql",
      "file_extension": "",
      "mimetype": "",
      "name": "sql",
      "version": "3.32.3"
    },
    "kernelspec": {
      "name": "SQLite",
      "display_name": "SQLite",
      "language": "sql"
    }
  },
  "nbformat_minor": 4,
  "nbformat": 4,
  "cells": [
    {
      "cell_type": "code",
      "source": "-- SQL query that returns user details including total spent and conversion status\nWITH cte_joined_data AS (\n  SELECT \n    u.id, u.country, u.gender, g.\"group\" AS group_ab, g.join_dt, g.device AS device, \n    a.dt, a.device AS activities_device, a.spent\n  FROM \n    users AS u\n    LEFT JOIN groups AS g ON u.id = g.uid\n    LEFT JOIN activity AS a ON u.id = a.uid\n), ready_data AS (\n  SELECT \n    id, group_ab, country, gender, device, \n    COALESCE(SUM(spent), 0) AS total_spent, \n    (CASE WHEN COALESCE(SUM(spent), 0) > 0 THEN 1 ELSE 0 END) AS converted\n  FROM \n    cte_joined_data\n  GROUP BY \n    id, 2, 3, 4, 5\n)\nSELECT *  \nFROM \n  ready_data;\n\n-- SQL query that includes the date along with user details\nWITH cte_joined_data AS (\n  SELECT \n    u.id, u.country, u.gender, g.\"group\" AS group_ab, g.join_dt, g.device AS device, \n    a.dt, a.device AS activities_device, a.spent\n  FROM \n    users AS u\n    LEFT JOIN groups AS g ON u.id = g.uid\n    LEFT JOIN activity AS a ON u.id = a.uid\n), ready_data AS (\n  SELECT \n    id, group_ab, country, gender, device, join_dt, \n    COALESCE(SUM(spent), 0) AS total_spent, \n    (CASE WHEN COALESCE(SUM(spent), 0) > 0 THEN 1 ELSE 0 END) AS converted\n  FROM \n    cte_joined_data\n  GROUP BY \n    id, 2, 3, 4, 5, 6\n)\nSELECT *  \nFROM \n  ready_data\nORDER BY \n  total_spent DESC;\n\n-- Additional queries related to cumulative conversion rates\nWITH join_dt_agg AS (\n  -- CTE 1: Calculate user count in each test group per join date\n),\nconvert_dt_agg AS (\n  -- CTE 2: Calculate converted user count in each test group per conversion date\n),\ncumulative_users AS (\n  -- CTE 3: Combine user counts and converted user counts, calculating cumulative sums\n),\ncumulative_conversion AS (\n  -- CTE 4: Calculate cumulative conversion rate for each test group and date\n)\n-- Final query: Compare cumulative conversion rates between test groups A and B for each date\nSELECT \n  a.dt,\n  a.cum_conversion_rate AS a_cum_convert,\n  b.cum_conversion_rate AS b_cum_convert,\n  b.cum_conversion_rate - a.cum_conversion_rate AS cum_diff\nFROM \n  cumulative_conversion AS a\n  INNER JOIN cumulative_conversion AS b ON a.dt = b.dt\n    AND a.test_group = 'A' AND b.test_group = 'B';\n",
      "metadata": {},
      "execution_count": null,
      "outputs": []
    }
  ]
}