-- Create table for housing data
CREATE TABLE IF NOT EXISTS housing (
    id SERIAL PRIMARY KEY,
    crim DOUBLE PRECISION,
    zn DOUBLE PRECISION,
    indus DOUBLE PRECISION,
    chas INTEGER,
    nox DOUBLE PRECISION,
    rm DOUBLE PRECISION,
    age DOUBLE PRECISION,
    dis DOUBLE PRECISION,
    rad INTEGER,
    tax INTEGER,
    ptratio DOUBLE PRECISION,
    b DOUBLE PRECISION,
    lstat DOUBLE PRECISION,
    medv DOUBLE PRECISION,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Optional: Create index on medv for queries
CREATE INDEX IF NOT EXISTS idx_medv ON housing(medv);
CREATE INDEX IF NOT EXISTS idx_created_at ON housing(created_at);
