import os
import pathlib
import urllib3

from bs4 import BeautifulSoup
import numpy as np
import pandas as pd

urllib3.disable_warnings()

file_path = pathlib.Path(__file__).parent.absolute()
data_path = os.path.abspath('%s/../data' % file_path)

STATES = np.loadtxt(
    os.path.join(data_path, 'state_abbreviations.txt'),
    dtype=np.str)
STATE_ABBREVS = STATES[:,1]

def load_and_write_all_polls(year, data_source='538', local_data=False):
    ''' Load and write all state-wise polling data for year 

    :param year: int, year of the election.
    :param data_source: str, either '538' or 'rcp'
        (Note: 'rcp' is deprecated as of 2024 due to changes
        in their website and data schema).
    :param local_data: bool, load master data file from data/ (True) or
        load from web (False).

    :return: None. Write all data to files in data/polls_{year}/
    '''

    if data_source == '538':
        # Load all polls for the current cycle:
        data_url = 'https://projects.fivethirtyeight.com/polls/data/president_polls.csv'
        data_path_local = os.path.join(data_path, 'polls_%s/president_polls_all.csv' % year)
        if local_data:
            master_data = pd.read_csv(data_path_local,
                parse_dates = ['start_date', 'end_date'])
        else:
            master_data = pd.read_csv(data_url,
                parse_dates = ['start_date', 'end_date'])
            master_data.to_csv(data_path_local, index=False)

        # Only use polls from current year:
        is_current_year = (master_data['end_date'].apply(lambda x: x.year) == year)
        master_data.query("@is_current_year",
            inplace=True)

        # Parse out and write state-level polls:
        for state in STATES:

            print('Writing polls for state %s' % state[1])

            _write_state_polls_538(master_data, state[0])


    elif data_source == 'rcp':
        master_table = _get_rcp_master_table()

        # State-level polls
        for abbr in STATE_ABBREVS:

            print('Getting polls for state %s' % abbr)

            abbr = abbr.lower()

            poll_url = _get_state_poll_url(abbr, year, master_table)

            if not poll_url:
                continue

            http = urllib3.PoolManager()
            html_doc = http.request('GET', poll_url)
            page = BeautifulSoup(html_doc.data, features="lxml")

            data = _all_state_data_to_df(page)

            data.to_csv('%s/polls_%s/%s_%s_poll.dat' % (
                data_path, year, abbr, year), index=False)

        # National polls for general election:
        print("Getting national level polls")
        nat_poll_url = _get_national_poll_url(year, master_table)

        http = urllib3.PoolManager()
        html_doc = http.request('GET', nat_poll_url)
        page = BeautifulSoup(html_doc.data, features="lxml")

        data = _all_state_data_to_df(page)

    data.to_csv('%s/polls_%s/national_%s_poll.dat' % (
        data_path, year, year), index=False)


# Private functions:

def _get_rcp_master_table():
    ''' Read RCP latest_polls html table. '''

    http = urllib3.PoolManager()
    html_doc = http.request(
        'GET',
        'http://www.realclearpolitics.com/epolls/latest_polls/president/#')

    page = BeautifulSoup(html_doc.data, features="lxml")
    return str(page.find(id="table-1"))


def _get_state_poll_url(abbr, year, master_table):
    ''' Get URL to state-level polls '''

    # Find URL string
    start = master_table.find('epolls/%s/president/%s' % (year, abbr))
    if(start == -1):
        print('No polls found for %s, skipping.' % abbr)
        return ''

    end = start + master_table[start::].find("html") + 4

    url = "http://www.realclearpolitics.com/%s%s" % \
        (master_table[start:end], '#polls')
    return url


def _get_national_poll_url(year, master_table):
    ''' Get URL to national-level poll '''

    # Find URL string
    start = master_table.find('epolls/%s/president/us/general_election' % year)
    if(start == -1):
        print('No national polls found, skipping.')
        return ''

    end = start + master_table[start::].find("html") + 4

    url = "http://www.realclearpolitics.com/%s%s" % \
        (master_table[start:end], '#polls')
    return url


def _all_state_data_to_df(page):
    ''' Get all state polling data from page and comple in dataframe '''

    # Compile all poll data for the state:
    poll_names = []
    poll_dates = []
    dem_perc = []
    rep_perc = []
    poll_sizes = []

    header = page.find(id="polling-data-full").find_all('tr')[0]
    # Does the democrat appear first in the table?
    dem_first = (str(header).find("(D)")) < str(header).find("(R)")

    poll_html_list = [
        x.find_all("td") for x in
        page.find(id="polling-data-full").find_all('tr')
    ][1::]

    for poll_html in poll_html_list:

        if dem_first:
            poll_dict = dict(
                zip(["poll",
                     "dates",
                     "size",
                     "error",
                     "dem",
                     "rep",
                     "margin"],
                    [y.get_text() for y in poll_html]))
        else:
            poll_dict = dict(
                zip(["poll",
                     "dates",
                     "size",
                     "error",
                     "rep",
                     "dem",
                     "margin"],
                    [y.get_text() for y in poll_html]))

        # Overwrite pollster with properly parsed name:
        try:
            pollster_name = poll_html[0].find(
                None, {"class": "normal_pollster_name"})
            poll_dict['poll'] = pollster_name.text
        except AttributeError:
            # Skip non-polls (e.g., RCP Average)
            continue

        # If no sample size given, skip:
        if poll_dict['size'] in ['LV', 'RV', '--']:
            continue

        # Append poll info to lists:
        poll_names.append(poll_dict["poll"].rstrip("*"))
        poll_dates.append(poll_dict["dates"])
        rep_perc.append(float(poll_dict["rep"]))
        dem_perc.append(float(poll_dict["dem"]))
        poll_sizes.append(int(poll_dict["size"].lstrip().split(" ")[0]))

    data = pd.DataFrame(list(
        zip(poll_names, poll_dates, rep_perc, dem_perc, poll_sizes)),
        columns=['Name', 'Date', 'Republican', 'Democrat', 'Size'])

    return data
