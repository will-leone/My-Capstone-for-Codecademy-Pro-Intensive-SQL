import sqlite3
import os


def connect(path, database):
    os.chdir(path)
    return sqlite3.connect(database)


def drop(path, database, table_foo, close=False):
    connection = connect(path, database)
    connection.execute(f"DROP TABLE {table_foo};")
    if close:
        connection.close()
    return


def csv_to_db(path, database, source_csv, close=True):
    connection = connect(path, database)
    connection.execute("CREATE TABLE IF NOT EXISTS subscriptions ( "
                       "  id integer NOT NULL, "
                       "  subscription_start text NOT NULL, "
                       "  subscription_end text, "
                       "  segment integer);")

    data = list()
    with open(source_csv, newline='') as csvReader:
        for row in csvReader:
            row = row.split(",")
            for value in row:
                column = row.index(value)
                if not value:
                    if column in [0, 3]:
                        row[column] = 0
                if "/" in value:
                    date = value.split("/")
                    for entry in date:
                        if len(entry) == 1:
                            date[date.index(entry)] = "0" + entry
                    row[column] = date[2] + "-" + date[0] + "-" + date[1]
            data.append([int(row[0]), row[1], row[2], int(row[3])])

    connection.executemany('INSERT INTO subscriptions ( '
                           '  id, '
                           '  subscription_start, '
                           '  subscription_end, '
                           '  segment) '
                           'VALUES (?, ?, ?, ?);', data)
    for column in ["subscription_end", "segment"]:
        connection.execute(f'UPDATE subscriptions '
                           f'SET {column} = NULL '
                           f'WHERE {column} = "";')
    connection.commit()
    if close:
        connection.close()
    return


def count_rows_with_null(path, database, table_foo):
    connection = connect(path, database)
    total_rows, null_rows = 0, 0
    for row in connection.execute(f'SELECT COUNT(*) '
                                  f'FROM {table_foo};'):
        total_rows = row[0]
    for row in connection.execute(f'SELECT COUNT(*) '
                                  f'FROM {table_foo} '
                                  f'WHERE subscription_end IS NULL;'):
        null_rows = row[0]
    percentage = round(100 * null_rows/total_rows, 2)
    return print(f"{null_rows} out of {total_rows} "
                 f"({percentage}%) rows have some null values.")


def show_rows(path, database, table_foo):
    connection = connect(path, database)
    data = list()
    try:
        print("First and last five records: \n")
        for row in connection.execute(f'SELECT * '
                                      f'FROM {table_foo};'):
            data.append(row)
    finally:
        for record in data[:5] + data[-5:]:
            print(record)
    print("\n" + str(len(data)) + " total records.")


try:
    drop(os.getcwd(), "Codeflix.db", "subscriptions")
    print("Removed prior version of Codeflix.db.")
finally:
    csv_to_db(os.getcwd(), "Codeflix.db", "Codeflix.csv")
    count_rows_with_null(os.getcwd(), "Codeflix.db", "subscriptions")
    show_rows(os.getcwd(), "Codeflix.db", "subscriptions")
