Class.new Sequel::Migration do
  def up
    execute <<-SQL
      CREATE OR REPLACE FUNCTION tier_notifications() RETURNS TRIGGER AS $notifications$
      BEGIN
        --
        -- Send NOTIFY events for every change to the calls table
        --
        IF (TG_OP = 'INSERT') THEN
            PERFORM pg_notify('tier_insert', row_to_json(NEW)::text);
            RETURN NEW;
        ELSIF (TG_OP = 'UPDATE') THEN
          IF NEW.state <> OLD.state THEN
            IF NEW.state = 'Receiving' THEN
              RETURN NEW;
            END IF;
            IF (NEW.state = 'Waiting') AND (OLD.state = 'Receiving') THEN
              RETURN NEW;
            END IF;
            PERFORM pg_notify('tier_update', row_to_json(NEW)::text);
            RETURN NEW;
          END IF;
        ELSIF (TG_OP = 'DELETE') THEN
            PERFORM pg_notify('tier_delete', row_to_json(OLD)::text);
            RETURN OLD;
        END IF;
        RETURN NULL; -- result is ignored since this is an AFTER trigger
      END;
      $notifications$ LANGUAGE plpgsql;
    SQL
    execute <<-SQL
      CREATE TRIGGER tier_insert
        AFTER INSERT ON tiers
        FOR EACH ROW
        EXECUTE PROCEDURE tier_notifications();
      CREATE TRIGGER tier_update
        AFTER UPDATE ON tiers
        FOR EACH ROW
        EXECUTE PROCEDURE tier_notifications();
      CREATE TRIGGER tier_delete
        BEFORE DELETE ON tiers
        FOR EACH ROW
        EXECUTE PROCEDURE tier_notifications();
    SQL

    execute <<-SQL
      CREATE OR REPLACE FUNCTION agent_notifications() RETURNS TRIGGER AS $notifications$
      BEGIN
        --
        -- Send NOTIFY events for every change to the calls table
        --
        IF (TG_OP = 'INSERT') THEN
            PERFORM pg_notify('agent_insert', row_to_json(NEW)::text);
            RETURN NULL;
        ELSIF (TG_OP = 'UPDATE') THEN
            IF OLD.status <> NEW.status THEN
              PERFORM pg_notify('agent_update', '{"name": "'||NEW.name||'", "status": "'||NEW.status||'"}');
            ELSIF OLD.state <> NEW.state THEN
              PERFORM pg_notify('agent_update', '{"name": "'||NEW.name||'", "state": "'||NEW.state||'"}');
            END IF;
            RETURN NULL;
        ELSIF (TG_OP = 'DELETE') THEN
            PERFORM pg_notify('agent_delete', row_to_json(OLD)::text);
            RETURN OLD;
        END IF;
        RETURN NULL; -- result is ignored since this is an AFTER trigger
      END;
      $notifications$ LANGUAGE plpgsql;
    SQL
    execute <<-SQL
      CREATE TRIGGER agent_insert
        AFTER INSERT ON agents
        FOR EACH ROW
        EXECUTE PROCEDURE agent_notifications();
      CREATE TRIGGER agent_update
        AFTER UPDATE ON agents
        FOR EACH ROW
        EXECUTE PROCEDURE agent_notifications();
      CREATE TRIGGER agent_delete
        BEFORE DELETE ON agents
        FOR EACH ROW
        EXECUTE PROCEDURE agent_notifications();
    SQL

    execute <<-SQL
      CREATE OR REPLACE FUNCTION member_notifications() RETURNS TRIGGER AS $notifications$
      BEGIN
        --
        -- Send NOTIFY events for every change to the calls table
        --
        IF (TG_OP = 'INSERT') THEN
            PERFORM pg_notify('member_insert', row_to_json(NEW)::text);
            RETURN NULL;
        ELSIF (TG_OP = 'UPDATE') THEN
            PERFORM pg_notify('member_update', row_to_json(NEW)::text);
            RETURN NULL;
        ELSIF (TG_OP = 'DELETE') THEN
            PERFORM pg_notify('member_delete', row_to_json(OLD)::text);
            RETURN OLD;
        END IF;
        RETURN NULL; -- result is ignored since this is an AFTER trigger
      END;
      $notifications$ LANGUAGE plpgsql;
    SQL
    execute <<-SQL
      CREATE TRIGGER member_insert
        AFTER INSERT ON members
        FOR EACH ROW
        EXECUTE PROCEDURE member_notifications();
      CREATE TRIGGER member_update
        AFTER UPDATE ON members
        FOR EACH ROW
        EXECUTE PROCEDURE member_notifications();
      CREATE TRIGGER member_delete
        BEFORE DELETE ON members
        FOR EACH ROW
        EXECUTE PROCEDURE member_notifications();
    SQL
  end

  def down
    execute 'DROP TRIGGER "agent_insert" on agents;'
    execute 'DROP TRIGGER "agent_update" on agents;'
    execute 'DROP TRIGGER "agent_delete" on agents;'
    execute 'DROP FUNCTION agent_notifications();'

    execute 'DROP TRIGGER "tier_insert" on tiers;'
    execute 'DROP TRIGGER "tier_update" on tiers;'
    execute 'DROP TRIGGER "tier_delete" on tiers;'
    execute 'DROP FUNCTION tier_notifications();'

    execute 'DROP TRIGGER "member_insert" on members;'
    execute 'DROP TRIGGER "member_update" on members;'
    execute 'DROP TRIGGER "member_delete" on members;'
    execute 'DROP FUNCTION member_notifications();'
  end
end
