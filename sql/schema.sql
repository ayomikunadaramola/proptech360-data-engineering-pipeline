CREATE TABLE IF NOT EXISTS dim_property (
    property_key BIGSERIAL PRIMARY KEY,
    property_id VARCHAR(20) NOT NULL UNIQUE,
    property_name VARCHAR(150) NOT NULL,
    city VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS dim_month (
    month_key BIGSERIAL PRIMARY KEY,
    month_date DATE NOT NULL UNIQUE,
    year INTEGER NOT NULL,
    month_number INTEGER NOT NULL
        CHECK (month_number BETWEEN 1 AND 12),
    month_name VARCHAR(20) NOT NULL
);

CREATE TABLE IF NOT EXISTS fact_property_month (
    property_key BIGINT NOT NULL,
    month_key BIGINT NOT NULL,

    total_units INTEGER NOT NULL
        CHECK (total_units >= 0),

    occupied_units INTEGER NOT NULL
        CHECK (occupied_units >= 0),

    occupancy_rate NUMERIC(8,6)
        CHECK (
            occupancy_rate IS NULL
            OR occupancy_rate BETWEEN 0 AND 1
        ),

    earned_monthly_rent_usd NUMERIC(14,2) NOT NULL
        CHECK (earned_monthly_rent_usd >= 0),

    resolved_orders INTEGER NOT NULL
        CHECK (resolved_orders >= 0),

    sla_eligible_orders INTEGER NOT NULL
        CHECK (sla_eligible_orders >= 0),

    sla_compliant_orders INTEGER NOT NULL
        CHECK (sla_compliant_orders >= 0),

    open_orders INTEGER NOT NULL
        CHECK (open_orders >= 0),

    sla_compliance_rate NUMERIC(8,6)
        CHECK (
            sla_compliance_rate IS NULL
            OR sla_compliance_rate BETWEEN 0 AND 1
        ),

    energy_kwh NUMERIC(14,2) NOT NULL
        CHECK (energy_kwh >= 0),

    floor_area_sqm NUMERIC(14,2) NOT NULL
        CHECK (floor_area_sqm > 0),

    energy_intensity_kwh_sqm NUMERIC(14,6)
        CHECK (
            energy_intensity_kwh_sqm IS NULL
            OR energy_intensity_kwh_sqm >= 0
        ),

    PRIMARY KEY (
        property_key,
        month_key
    ),

    CONSTRAINT fk_fact_property
        FOREIGN KEY (property_key)
        REFERENCES dim_property(property_key),

    CONSTRAINT fk_fact_month
        FOREIGN KEY (month_key)
        REFERENCES dim_month(month_key),

    CONSTRAINT chk_occupied_not_above_total
        CHECK (
            occupied_units <= total_units
        ),

    CONSTRAINT chk_sla_compliant_not_above_eligible
        CHECK (
            sla_compliant_orders
            <= sla_eligible_orders
        )
);

CREATE INDEX IF NOT EXISTS idx_fact_property
    ON fact_property_month(property_key);

CREATE INDEX IF NOT EXISTS idx_fact_month
    ON fact_property_month(month_key);