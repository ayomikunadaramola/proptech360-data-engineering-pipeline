SELECT
    dp.property_id,
    dp.property_name,
    dp.city,

    SUM(f.occupied_units) AS occupied_unit_months,
    SUM(f.total_units) AS available_unit_months,

    ROUND(
        SUM(f.occupied_units)::NUMERIC
        / NULLIF(SUM(f.total_units), 0),
        4
    ) AS average_occupancy_rate,

    ROUND(
        100.0 * SUM(f.occupied_units)::NUMERIC
        / NULLIF(SUM(f.total_units), 0),
        2
    ) AS average_occupancy_pct

FROM fact_property_month AS f

JOIN dim_property AS dp
    ON f.property_key = dp.property_key

JOIN dim_month AS dm
    ON f.month_key = dm.month_key

WHERE dm.month_date
      BETWEEN DATE '2026-01-01'
          AND DATE '2026-06-30'

GROUP BY
    dp.property_id,
    dp.property_name,
    dp.city

ORDER BY
    average_occupancy_rate DESC,
    dp.property_id;


SELECT
    dm.month_date,
    dp.city,

    ROUND(
        SUM(f.earned_monthly_rent_usd),
        2
    ) AS earned_contractual_rent_usd

FROM fact_property_month AS f

JOIN dim_property AS dp
    ON f.property_key = dp.property_key

JOIN dim_month AS dm
    ON f.month_key = dm.month_key

GROUP BY
    dm.month_date,
    dp.city

ORDER BY
    dm.month_date,
    dp.city;


SELECT
    dp.property_id,
    dp.property_name,
    dp.city,

    SUM(f.resolved_orders) AS resolved_orders,

    SUM(f.sla_eligible_orders)
        AS sla_eligible_resolved_orders,

    SUM(f.sla_compliant_orders)
        AS sla_compliant_orders,

    SUM(
        f.resolved_orders
        - f.sla_eligible_orders
    ) AS excluded_resolved_orders,

    SUM(f.open_orders)
        AS unresolved_open_orders,

    ROUND(
        SUM(f.sla_compliant_orders)::NUMERIC
        / NULLIF(
            SUM(f.sla_eligible_orders),
            0
        ),
        4
    ) AS sla_compliance_rate,

    ROUND(
        100.0
        * SUM(f.sla_compliant_orders)::NUMERIC
        / NULLIF(
            SUM(f.sla_eligible_orders),
            0
        ),
        2
    ) AS sla_compliance_pct

FROM fact_property_month AS f

JOIN dim_property AS dp
    ON f.property_key = dp.property_key

GROUP BY
    dp.property_id,
    dp.property_name,
    dp.city

ORDER BY
    sla_compliance_rate DESC NULLS LAST,
    dp.property_id;


WITH energy_comparison AS (
    SELECT
        dp.property_id,
        dp.property_name,
        dp.city,
        dm.month_date,

        f.energy_kwh,
        f.energy_intensity_kwh_sqm,

        AVG(
            f.energy_intensity_kwh_sqm
        ) OVER (
            PARTITION BY dm.month_date
        ) AS portfolio_monthly_avg_intensity

    FROM fact_property_month AS f

    JOIN dim_property AS dp
        ON f.property_key = dp.property_key

    JOIN dim_month AS dm
        ON f.month_key = dm.month_key

    WHERE
        f.energy_intensity_kwh_sqm
        IS NOT NULL
)

SELECT
    property_id,
    property_name,
    city,
    month_date,

    ROUND(
        energy_kwh,
        2
    ) AS energy_kwh,

    ROUND(
        energy_intensity_kwh_sqm,
        4
    ) AS energy_intensity_kwh_sqm,

    ROUND(
        portfolio_monthly_avg_intensity,
        4
    ) AS portfolio_monthly_avg_intensity

FROM energy_comparison

WHERE
    energy_intensity_kwh_sqm
    > portfolio_monthly_avg_intensity

ORDER BY
    month_date,
    energy_intensity_kwh_sqm DESC;