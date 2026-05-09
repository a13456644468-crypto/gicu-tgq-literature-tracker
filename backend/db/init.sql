CREATE TABLE IF NOT EXISTS journals (
    id SERIAL PRIMARY KEY,
    category VARCHAR(50) NOT NULL,
    name VARCHAR(200) NOT NULL,
    issn VARCHAR(20),
    pubmed_search_term VARCHAR(500),
    is_builtin BOOLEAN DEFAULT true,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS papers (
    id SERIAL PRIMARY KEY,
    journal_id INTEGER REFERENCES journals(id),
    pmid VARCHAR(20) UNIQUE NOT NULL,
    title TEXT NOT NULL,
    authors TEXT,
    abstract TEXT,
    doi VARCHAR(100),
    pub_date DATE,
    pubmed_url VARCHAR(500),
    is_new BOOLEAN DEFAULT true,
    is_read BOOLEAN DEFAULT false,
    fetched_at TIMESTAMP DEFAULT NOW(),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS checklists (
    id SERIAL PRIMARY KEY,
    checklist_date DATE NOT NULL,
    shift VARCHAR(20) DEFAULT 'day',
    bed_number VARCHAR(20) NOT NULL,
    patient_name VARCHAR(100) NOT NULL,
    diagnosis TEXT NOT NULL,
    pathogen TEXT,
    antibiotics TEXT,
    anticoagulation TEXT,
    nutrition TEXT,
    planned_io TEXT,
    actual_io TEXT,
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_papers_journal_id ON papers(journal_id);
CREATE INDEX IF NOT EXISTS idx_papers_pub_date ON papers(pub_date DESC);
CREATE INDEX IF NOT EXISTS idx_papers_is_new ON papers(is_new);
CREATE INDEX IF NOT EXISTS idx_checklists_date ON checklists(checklist_date DESC);
CREATE INDEX IF NOT EXISTS idx_checklists_bed ON checklists(bed_number);

INSERT INTO journals (category, name, issn, pubmed_search_term, is_builtin)
VALUES
('critical_care', 'Critical Care Medicine', '0090-3493', '"Critical Care Medicine"[Journal]', true),
('critical_care', 'Intensive Care Medicine', '0342-4642', '"Intensive Care Medicine"[Journal]', true),
('critical_care', 'Critical Care', '1364-8535', '"Critical Care"[Journal]', true),
('critical_care', 'Journal of Critical Care', '0883-9441', '"Journal of Critical Care"[Journal]', true),
('critical_care', 'Annals of Intensive Care', '2110-5820', '"Annals of Intensive Care"[Journal]', true),
('lung_transplant', 'Journal of Heart and Lung Transplantation', '1053-2498', '"Journal of Heart and Lung Transplantation"[Journal]', true),
('lung_transplant', 'Transplantation', '0041-1337', '"Transplantation"[Journal]', true),
('lung_transplant', 'American Journal of Transplantation', '1600-6135', '"American Journal of Transplantation"[Journal]', true),
('lung_transplant', 'Lung Cancer', '0169-5002', '"Lung Cancer"[Journal]', true),
('lung_transplant', 'Respiratory Care', '0020-1324', '"Respiratory Care"[Journal]', true)
ON CONFLICT DO NOTHING;
