--------------------------------------------------------------------------------
-- BeST - Πίνακες που δεν περιλαμβάνονταν στο install.sql
-- Ανακατασκευή με βάση την τεκμηρίωση (docs/database-architecture.md) και
-- τη χρήση τους στην εφαρμογή APEX (apex/f274115.sql).
-- Εκτέλεση ΜΕΤΑ το install.sql.
--------------------------------------------------------------------------------

-- ESSAYS: στήλες που χρησιμοποιεί η εφαρμογή αλλά λείπουν από το install.sql
ALTER TABLE "ESSAYS" ADD (
    "UNIVERSITY_ID" VARCHAR2(20 CHAR),
    "DEPARTMENT_ID" VARCHAR2(20 CHAR),
    "MANUAL_FLG"    NUMBER(1) DEFAULT 0
);
COMMENT ON COLUMN "ESSAYS"."UNIVERSITY_ID" IS 'Πανεπιστήμιο';
COMMENT ON COLUMN "ESSAYS"."DEPARTMENT_ID" IS 'Τμήμα';
COMMENT ON COLUMN "ESSAYS"."MANUAL_FLG"    IS 'Θέμα που προτάθηκε από φοιτητή (1: Ναι, 0: Όχι)';

--------------------------------------------------------------------------------
-- Sequences
--------------------------------------------------------------------------------
CREATE SEQUENCE "SEQ_USER_LOG"      START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE "SEQ_USER_TIMELIST" START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE "SEQ_USER_CALENDAR" START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE "SEQ_REQUESTS"      START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE "SEQ_REQ_STATUS"    START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE "SEQ_REQ_PAPERS"    START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE "SEQ_CHATBOT_HIST"  START WITH 1 INCREMENT BY 1 NOCACHE;

--------------------------------------------------------------------------------
-- USER_LOG: ιστορικό συνδέσεων (κέντρο ειδοποιήσεων - "ημέρες από την τελευταία σύνδεση")
--------------------------------------------------------------------------------
CREATE TABLE "USER_LOG" (
    "ID"       NUMBER NOT NULL,
    "USER_ID"  NUMBER NOT NULL,
    "LOG_DATE" DATE   DEFAULT SYSDATE NOT NULL,
    CONSTRAINT "USER_LOG_PK"  PRIMARY KEY ("ID"),
    CONSTRAINT "USER_LOG_FK1" FOREIGN KEY ("USER_ID") REFERENCES "USERS" ("ID")
);
CREATE INDEX "USER_LOG_I1" ON "USER_LOG" ("USER_ID", "LOG_DATE");
COMMENT ON COLUMN "USER_LOG"."ID"       IS 'Μοναδικό Αναγνωριστικό';
COMMENT ON COLUMN "USER_LOG"."USER_ID"  IS 'Αναγνωριστικό χρήστη';
COMMENT ON COLUMN "USER_LOG"."LOG_DATE" IS 'Ημερομηνία - Ώρα σύνδεσης';

--------------------------------------------------------------------------------
-- USER_TIMELIST: ώρες διαθεσιμότητας καθηγητή (slots 30 λεπτών, 08:00 - 21:00)
--------------------------------------------------------------------------------
CREATE TABLE "USER_TIMELIST" (
    "ID"         NUMBER NOT NULL,
    "USER_ID"    NUMBER NOT NULL,
    "CAL_TIME"   VARCHAR2(5 CHAR) NOT NULL,
    "CREATED"    DATE,
    "CREATED_BY" NUMBER,
    "UPDATED"    DATE,
    "UPDATED_BY" NUMBER,
    CONSTRAINT "USER_TIMELIST_PK"  PRIMARY KEY ("ID"),
    CONSTRAINT "USER_TIMELIST_UK1" UNIQUE ("USER_ID", "CAL_TIME"),
    CONSTRAINT "USER_TIMELIST_FK1" FOREIGN KEY ("USER_ID") REFERENCES "USERS" ("ID")
);
COMMENT ON COLUMN "USER_TIMELIST"."USER_ID"  IS 'Αναγνωριστικό χρήστη (καθηγητή)';
COMMENT ON COLUMN "USER_TIMELIST"."CAL_TIME" IS 'Ώρα διαθεσιμότητας (HH24:MI)';

--------------------------------------------------------------------------------
-- USER_CALENDAR: ραντεβού / τηλεδιασκέψεις φοιτητή - καθηγητή
--------------------------------------------------------------------------------
CREATE TABLE "USER_CALENDAR" (
    "ID"         NUMBER NOT NULL,
    "USER_ID"    NUMBER NOT NULL,
    "TO_USER"    NUMBER NOT NULL,
    "CLD_DATE"   DATE   NOT NULL,
    "DESCR"      VARCHAR2(4000 CHAR),
    "NOTES"      VARCHAR2(4000 CHAR),
    "TELE_LINK"  VARCHAR2(1000 CHAR),
    "STATUS"     NUMBER(1) DEFAULT 1 NOT NULL,
    "TYPE"       NUMBER(1) NOT NULL,
    "CREATED"    DATE,
    "CREATED_BY" NUMBER,
    "UPDATED"    DATE,
    "UPDATED_BY" NUMBER,
    CONSTRAINT "USER_CALENDAR_PK"  PRIMARY KEY ("ID"),
    CONSTRAINT "USER_CALENDAR_FK1" FOREIGN KEY ("USER_ID") REFERENCES "USERS" ("ID"),
    CONSTRAINT "USER_CALENDAR_FK2" FOREIGN KEY ("TO_USER") REFERENCES "USERS" ("ID"),
    CONSTRAINT "USER_CALENDAR_CK1" CHECK ("STATUS" IN (0, 1)),
    CONSTRAINT "USER_CALENDAR_CK2" CHECK ("TYPE" IN (1, 2))
);
CREATE INDEX "USER_CALENDAR_I1" ON "USER_CALENDAR" ("TO_USER", "CLD_DATE");
COMMENT ON COLUMN "USER_CALENDAR"."USER_ID"   IS 'Αναγνωριστικό χρήστη (φοιτητή)';
COMMENT ON COLUMN "USER_CALENDAR"."TO_USER"   IS 'Αναγνωριστικό καθηγητή (παραλήπτης αιτήματος)';
COMMENT ON COLUMN "USER_CALENDAR"."CLD_DATE"  IS 'Ημερομηνία και ώρα συνάντησης';
COMMENT ON COLUMN "USER_CALENDAR"."DESCR"     IS 'Περιγραφή συνάντησης';
COMMENT ON COLUMN "USER_CALENDAR"."NOTES"     IS 'Πρόσθετες πληροφορίες / σημειώσεις';
COMMENT ON COLUMN "USER_CALENDAR"."TELE_LINK" IS 'Σύνδεσμος τηλεδιάσκεψης';
COMMENT ON COLUMN "USER_CALENDAR"."STATUS"    IS 'Κατάσταση (1: Ενεργό, 0: Ανενεργό)';
COMMENT ON COLUMN "USER_CALENDAR"."TYPE"      IS 'Τύπος (1: Ραντεβού, 2: Τηλεδιάσκεψη)';

--------------------------------------------------------------------------------
-- REQUESTS: αιτήσεις ανάληψης πτυχιακής εργασίας
--------------------------------------------------------------------------------
CREATE TABLE "REQUESTS" (
    "ID"         NUMBER NOT NULL,
    "REF_DATE"   DATE   DEFAULT SYSDATE NOT NULL,
    "FROM_USER"  NUMBER NOT NULL,
    "TO_USER"    NUMBER NOT NULL,
    "IS_ACTIVE"  NUMBER(1) DEFAULT 1 NOT NULL,
    "ESSAY_ID"   NUMBER NOT NULL,
    "GRADE"      NUMBER(4,2),
    "CREATED"    DATE,
    "CREATED_BY" NUMBER,
    "UPDATED"    DATE,
    "UPDATED_BY" NUMBER,
    CONSTRAINT "REQUESTS_PK"  PRIMARY KEY ("ID"),
    CONSTRAINT "REQUESTS_FK1" FOREIGN KEY ("FROM_USER") REFERENCES "USERS" ("ID"),
    CONSTRAINT "REQUESTS_FK2" FOREIGN KEY ("TO_USER")   REFERENCES "USERS" ("ID"),
    CONSTRAINT "REQUESTS_FK3" FOREIGN KEY ("ESSAY_ID")  REFERENCES "ESSAYS" ("ID"),
    CONSTRAINT "REQUESTS_CK1" CHECK ("IS_ACTIVE" IN (0, 1)),
    CONSTRAINT "REQUESTS_CK2" CHECK ("GRADE" BETWEEN 0 AND 10)
);
CREATE INDEX "REQUESTS_I1" ON "REQUESTS" ("FROM_USER");
CREATE INDEX "REQUESTS_I2" ON "REQUESTS" ("TO_USER");
COMMENT ON COLUMN "REQUESTS"."REF_DATE"  IS 'Ημερομηνία Κατάθεσης';
COMMENT ON COLUMN "REQUESTS"."FROM_USER" IS 'Κατάθεση Από (φοιτητής)';
COMMENT ON COLUMN "REQUESTS"."TO_USER"   IS 'Κατάθεση Σε (καθηγητής)';
COMMENT ON COLUMN "REQUESTS"."IS_ACTIVE" IS 'Ένδειξη κατάστασης (0: Μη ενεργή, 1: Ενεργή)';
COMMENT ON COLUMN "REQUESTS"."ESSAY_ID"  IS 'Συσχέτιση με πτυχιακή εργασία (ESSAYS)';
COMMENT ON COLUMN "REQUESTS"."GRADE"     IS 'Βαθμός';

--------------------------------------------------------------------------------
-- REQUEST_STATUS: ιστορικό καταστάσεων αίτησης (κωδικοί ST:xx από CODE_LIST_VALUES)
--------------------------------------------------------------------------------
CREATE TABLE "REQUEST_STATUS" (
    "ID"          NUMBER NOT NULL,
    "REQ_ID"      NUMBER NOT NULL,
    "STATUS_DATE" DATE   DEFAULT SYSDATE NOT NULL,
    "STATUS_CODE" VARCHAR2(20 CHAR) NOT NULL,
    "USER_ID"     NUMBER NOT NULL,
    "NOTES"       VARCHAR2(4000 CHAR),
    "CREATED"     DATE,
    "CREATED_BY"  NUMBER,
    "UPDATED"     DATE,
    "UPDATED_BY"  NUMBER,
    CONSTRAINT "REQUEST_STATUS_PK"  PRIMARY KEY ("ID"),
    CONSTRAINT "REQUEST_STATUS_FK1" FOREIGN KEY ("REQ_ID")  REFERENCES "REQUESTS" ("ID") ON DELETE CASCADE,
    CONSTRAINT "REQUEST_STATUS_FK2" FOREIGN KEY ("USER_ID") REFERENCES "USERS" ("ID")
);
CREATE INDEX "REQUEST_STATUS_I1" ON "REQUEST_STATUS" ("REQ_ID", "STATUS_DATE");
COMMENT ON COLUMN "REQUEST_STATUS"."REQ_ID"      IS 'Συσχέτιση με αίτηση (REQUESTS)';
COMMENT ON COLUMN "REQUEST_STATUS"."STATUS_DATE" IS 'Ημερομηνία - Ώρα καταγραφής';
COMMENT ON COLUMN "REQUEST_STATUS"."STATUS_CODE" IS 'Κωδικός Κατάστασης';
COMMENT ON COLUMN "REQUEST_STATUS"."USER_ID"     IS 'Καταγραφή Από';
COMMENT ON COLUMN "REQUEST_STATUS"."NOTES"       IS 'Σημειώσεις (π.χ. αιτιολογία απόρριψης)';

--------------------------------------------------------------------------------
-- REQUEST_PAPERS: αρχεία που υποβάλλει ο φοιτητής για την αίτηση
--------------------------------------------------------------------------------
CREATE TABLE "REQUEST_PAPERS" (
    "ID"         NUMBER NOT NULL,
    "REQ_ID"     NUMBER NOT NULL,
    "FILE_NAME"  VARCHAR2(255 CHAR),
    "MIME_TYPE"  VARCHAR2(255 CHAR),
    "FILE_BLOB"  BLOB,
    "CREATED"    DATE,
    "CREATED_BY" NUMBER,
    "UPDATED"    DATE,
    "UPDATED_BY" NUMBER,
    CONSTRAINT "REQUEST_PAPERS_PK"  PRIMARY KEY ("ID"),
    CONSTRAINT "REQUEST_PAPERS_FK1" FOREIGN KEY ("REQ_ID") REFERENCES "REQUESTS" ("ID") ON DELETE CASCADE
);
COMMENT ON COLUMN "REQUEST_PAPERS"."REQ_ID"    IS 'Συσχέτιση με αίτηση (REQUESTS)';
COMMENT ON COLUMN "REQUEST_PAPERS"."FILE_NAME" IS 'Όνομα αρχείου αναφοράς';
COMMENT ON COLUMN "REQUEST_PAPERS"."MIME_TYPE" IS 'Τύπος αρχείου';
COMMENT ON COLUMN "REQUEST_PAPERS"."FILE_BLOB" IS 'Αρχείο (δυαδικά δεδομένα)';

--------------------------------------------------------------------------------
-- CHATBOT_HISTORY: ιστορικό συνομιλίας με το chatbot ανά session
--------------------------------------------------------------------------------
CREATE TABLE "CHATBOT_HISTORY" (
    "ID"         NUMBER NOT NULL,
    "SESSION_ID" VARCHAR2(100 CHAR) NOT NULL,
    "SENDER"     VARCHAR2(10 CHAR)  NOT NULL,
    "MESSAGE"    CLOB,
    "CREATED"    TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT "CHATBOT_HISTORY_PK"  PRIMARY KEY ("ID"),
    CONSTRAINT "CHATBOT_HISTORY_CK1" CHECK ("SENDER" IN ('USER', 'BOT'))
);
CREATE INDEX "CHATBOT_HISTORY_I1" ON "CHATBOT_HISTORY" ("SESSION_ID", "CREATED");

--------------------------------------------------------------------------------
-- Triggers: ID από sequence + audit στήλες (ίδιο pattern με το install.sql)
--------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER "TRG_USER_LOG"
BEFORE INSERT ON "USER_LOG" FOR EACH ROW
BEGIN
    IF :NEW.ID IS NULL THEN :NEW.ID := SEQ_USER_LOG.NEXTVAL; END IF;
    IF :NEW.LOG_DATE IS NULL THEN :NEW.LOG_DATE := SYSDATE; END IF;
END;
/
CREATE OR REPLACE TRIGGER "TRG_USER_TIMELIST"
BEFORE INSERT OR UPDATE ON "USER_TIMELIST" FOR EACH ROW
BEGIN
    IF INSERTING THEN
        IF :NEW.ID IS NULL THEN :NEW.ID := SEQ_USER_TIMELIST.NEXTVAL; END IF;
        :NEW.CREATED := SYSDATE; :NEW.CREATED_BY := v('USER_ID');
    ELSE
        :NEW.UPDATED := SYSDATE; :NEW.UPDATED_BY := v('USER_ID');
    END IF;
END;
/
CREATE OR REPLACE TRIGGER "TRG_USER_CALENDAR"
BEFORE INSERT OR UPDATE ON "USER_CALENDAR" FOR EACH ROW
BEGIN
    IF INSERTING THEN
        IF :NEW.ID IS NULL THEN :NEW.ID := SEQ_USER_CALENDAR.NEXTVAL; END IF;
        :NEW.CREATED := SYSDATE; :NEW.CREATED_BY := v('USER_ID');
    ELSE
        :NEW.UPDATED := SYSDATE; :NEW.UPDATED_BY := v('USER_ID');
    END IF;
END;
/
CREATE OR REPLACE TRIGGER "TRG_REQUESTS"
BEFORE INSERT OR UPDATE ON "REQUESTS" FOR EACH ROW
BEGIN
    IF INSERTING THEN
        IF :NEW.ID IS NULL THEN :NEW.ID := SEQ_REQUESTS.NEXTVAL; END IF;
        :NEW.CREATED := SYSDATE; :NEW.CREATED_BY := v('USER_ID');
    ELSE
        :NEW.UPDATED := SYSDATE; :NEW.UPDATED_BY := v('USER_ID');
    END IF;
END;
/
CREATE OR REPLACE TRIGGER "TRG_REQUEST_STATUS"
BEFORE INSERT OR UPDATE ON "REQUEST_STATUS" FOR EACH ROW
BEGIN
    IF INSERTING THEN
        IF :NEW.ID IS NULL THEN :NEW.ID := SEQ_REQ_STATUS.NEXTVAL; END IF;
        :NEW.CREATED := SYSDATE; :NEW.CREATED_BY := v('USER_ID');
    ELSE
        :NEW.UPDATED := SYSDATE; :NEW.UPDATED_BY := v('USER_ID');
    END IF;
END;
/
CREATE OR REPLACE TRIGGER "TRG_REQUEST_PAPERS"
BEFORE INSERT OR UPDATE ON "REQUEST_PAPERS" FOR EACH ROW
BEGIN
    IF INSERTING THEN
        IF :NEW.ID IS NULL THEN :NEW.ID := SEQ_REQ_PAPERS.NEXTVAL; END IF;
        :NEW.CREATED := SYSDATE; :NEW.CREATED_BY := v('USER_ID');
    ELSE
        :NEW.UPDATED := SYSDATE; :NEW.UPDATED_BY := v('USER_ID');
    END IF;
END;
/
CREATE OR REPLACE TRIGGER "TRG_CHATBOT_HISTORY"
BEFORE INSERT ON "CHATBOT_HISTORY" FOR EACH ROW
BEGIN
    IF :NEW.ID IS NULL THEN :NEW.ID := SEQ_CHATBOT_HIST.NEXTVAL; END IF;
END;
/
