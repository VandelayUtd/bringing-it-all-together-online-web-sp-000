require 'pry'

class Dog
    attr_accessor :name, :breed
    attr_reader :id

    def initialize(id:nil, name:, breed:)
        @id = id
        @name = name
        @breed = breed
    end

    def self.create_table
        sql = <<-SQL 
            CREATE TABLE IF NOT EXISTS dogs(
                id INTEGER PRIMARY KEY,
                name TEXT, 
                breed TEXT
            )
        SQL
        DB[:conn].execute(sql)
    end

    def self.drop_table
        DB[:conn].execute("DROP TABLE dogs")
    end

    def self.create(name:, breed:)
        new_dog = self.new(name:name, breed:breed)
        new_dog.save
    end

    def update
        sql = "UPDATE dogs SET name = ?, breed = ? WHERE id = ?"
        DB[:conn].execute(sql, self.name, self.breed, self.id)
    end

    def save
        if self.id
            self.update
        else
            sql = <<-SQL 
                INSERT INTO dogs(name, breed)
                VALUES (?, ?)
            SQL
            DB[:conn].execute(sql, self.name, self.breed)
            @id = DB[:conn].execute("SELECT last_insert_rowid() FROM dogs")[0][0]
        end
        self
    end

    def self.new_from_db(row)
        new_dog = self.new(id:row[0], name:row[1], breed:row[2])
        new_dog
    end

    def self.find_by_id(id)
        sql = <<-SQL 
        SELECT * 
        FROM dogs
        WHERE id = ?
        SQL

        DB[:conn].execute(sql, id).map do |row|
            self.new_from_db(row)
        end.first
    end

    def self.find_by_name(name)
        sql = <<-SQL 
            SELECT * 
            FROM dogs
            WHERE name = ?
        SQL
        DB[:conn].execute(sql, name).map do |row|
            self.new_from_db(row)
        end.first
    end

    def self.find_or_create_by(hash)
        dog = DB[:conn].execute("SELECT * FROM dogs WHERE name = ? AND breed = ?", hash[:name], hash[:breed])
        if !dog.empty?
            new_dog = self.new_from_db(dog[0])
        else
            new_dog = self.create(name:hash[:name], breed:hash[:breed])
        end
        new_dog
    end
end