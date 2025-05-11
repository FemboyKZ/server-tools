def create_wl():
    with open("manual.txt", "r") as file1:
        content1 = file1.readlines()

    with open("group.txt", "r") as file2:
        content2 = file2.readlines()

    with open("whitelist.txt", "w") as file3:
        file3.writelines(content1)
        file3.write("\n")
        file3.writelines(content2)
        file3.write("\n")


if __name__ == "__main__":
    create_wl()
    print("whitelist.txt updated")
