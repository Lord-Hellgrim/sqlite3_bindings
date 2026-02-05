package sqlite

import "core:fmt"
import "core:time"


main :: proc() {

    fmt.println("Working?")

	db: ^sqlite3
	stmt: ^sqlite3_stmt
	
	sqlite3_open("expenses.db", &db)

	if db == nil {
		fmt.println("Failed to open DB\n")
		return
	}

	fmt.println("Performing query...\n")

    sqlite3_exec(db, "CREATE TABLE expenses (texts TEXT, ints INTEGER, floats FLOAT);", nil, nil, nil)
    sqlite3_exec(db, "INSERT INTO expenses (texts, ints, floats) VALUES (\"a\", 0, 0.0)", nil, nil, nil)
    sqlite3_exec(db, "INSERT INTO expenses (texts, ints, floats) VALUES (\"b\", 1, 1.0)", nil, nil, nil)
    sqlite3_exec(db, "INSERT INTO expenses (texts, ints, floats) VALUES (\"c\", 2, 2.0)", nil, nil, nil)

	sqlite3_prepare_v2(db, "select * from expenses", -1, &stmt, nil)
	
	fmt.println("Got results:\n")
	for (sqlite3_step(stmt) != SQLITE_DONE) {
		i: i32
		num_cols: i32 = sqlite3_column_count(stmt)
		for i = 0; i < num_cols; i += 1 {
			switch (sqlite3_column_type(stmt, i))
			{
			case (SQLITE3_TEXT):
				fmt.println(sqlite3_column_text(stmt, i))
			case (SQLITE_INTEGER):
				fmt.println(sqlite3_column_int(stmt, i))
			case (SQLITE_FLOAT):
				fmt.println(sqlite3_column_double(stmt, i))
			case:
                panic("not suppsed")
            }
		}
		fmt.println("\n")

	}

	sqlite3_finalize(stmt)

    sqlite3_exec(db, "DROP TABLE expenses;", nil, nil, nil)

	sqlite3_close(db)

	return
    
}

