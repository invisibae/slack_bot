import os
import zipfile
import csv
import pandas as pd
from slack import WebClient
from slack.errors import SlackApiError
from datetime import date
from datetime import timedelta



slack_token = os.environ["SLACK_API_TOKEN"]
client = WebClient(token=slack_token)

allegations = open('./data/allegations_test.csv', 'r')
csv_obj = csv.DictReader(allegations)
csv_list = list(csv_obj)

today = date.today()
three_days_ago = today - timedelta(days = 4)




allegations_for_slack = [d for d in csv_list if date.fromisoformat(d['date_filed'])>= three_days_ago]


for allegation in allegations_for_slack:
    # print(allegation["date_filed"])
    # print('--------')
    try:
      response = client.chat_postMessage(
        channel="slack-bots",
        text= f"On {allegation['date_filed']}, workers at {allegation['name']} in {allegation['city']}, {allegation['state']} recently made allegations of {allegation['allegations']}. \nYou can find out more about this case at {allegation['url']}."
      )
    except SlackApiError as e:
      # You will get a SlackApiError if "ok" is False
      assert e.response["error"]  # str like 'invalid_auth', 'channel_not_found'
