import requests
import xmltodict
import sys


def fetch_and_save_member_ids(group_url_name):
    url = f"https://steamcommunity.com/groups/{group_url_name}/memberslistxml/?xml=1"

    response = requests.get(url)
    if response.status_code != 200:
        raise Exception(f"Error fetching data: {response.status_code}")

    data_dict = xmltodict.parse(response.content)

    member_ids = data_dict["memberList"]["members"]["steamID64"]
    sorted_ids = sorted(member_ids)

    with open(f"{txt_name}.txt", "w") as file:
        for steamid in sorted_ids:
            file.write(f"{steamid}\n")


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python3 list_members.py <txt_file_name> <group_url>")
        sys.exit(1)
    txt_name = sys.argv[1]
    group_url_name = sys.argv[2]
    fetch_and_save_member_ids(group_url_name)
    print(f"Member IDs have been saved to {txt_name}.txt")
