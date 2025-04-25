import os
import kustoQuery
import utils
from azure.kusto.data import KustoClient
from azure.kusto.data.exceptions import KustoServiceError
from azure.kusto.data.helpers import dataframe_from_result_table

from flask import (Flask, redirect, render_template, request,
                   send_from_directory, url_for)

app = Flask(__name__)


@app.route('/')
def index():
   print('Request for index page received')
   return render_template('index.html')

@app.route('/favicon.ico')
def favicon():
    return send_from_directory(os.path.join(app.root_path, 'static'),
                               'favicon.ico', mimetype='image/vnd.microsoft.icon')

@app.route('/query', methods=['POST'])
def hello():
   name = request.form.get('name')

   if name:
        print('Request for hello page received with name=%s' % name)

        print("Kusto Query App is starting...")

        app = kustoQuery.KustoQueryApp()
        app.load_configs(app.CONFIG_FILE_NAME)

        if app.config.authentication_mode == "UserPrompt":
            app.wait_for_user_to_proceed("You will be prompted for credentials during this script. Please return to the console after authenticating.")

        kusto_connection_string = utils.Utils.Authentication.generate_connection_string(app.config.kusto_uri, app.config.authentication_mode)
        print(f"Using cluster URI: {app.config.kusto_uri}")

        if not kusto_connection_string:
            utils.Utils.error_handler("Connection String error. Please validate your configuration file.")
        else:
            with KustoClient(kusto_connection_string) as kusto_client:
                app.query_table(kusto_client, app.config.database_name, app.config.table_name)

        print("\nKusto Query App done")

        return render_template('hello.html', name = name)
   else:
        print('Request for hello page received with no name or blank name -- redirecting')
        return redirect(url_for('index'))

if __name__ == '__main__':
    app.run()
