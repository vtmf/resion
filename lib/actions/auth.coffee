###
Copyright 2016-2017 Resin.io

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
###

exports.login	=
	signature: 'login'
	description: 'login to resin.io'
	help: '''
		Use this command to login to your resin.io account.

		This command will prompt you to login using the following login types:

		- Web authorization: open your web browser and prompt you to authorize the CLI
		from the dashboard.

		- Credentials: using email/password and 2FA.

		- Token: using a session token or API key (experimental) from the preferences page.

		Examples:

			$ resin login
			$ resin login --web
			$ resin login --token "..."
			$ resin login --credentials
			$ resin login --credentials --email johndoe@gmail.com --password secret
	'''
	options: [
		{
			signature: 'token'
			description: 'session token or API key (experimental)'
			parameter: 'token'
			alias: 't'
		}
		{
			signature: 'web'
			description: 'web-based login'
			boolean: true
			alias: 'w'
		}
		{
			signature: 'credentials'
			description: 'credential-based login'
			boolean: true
			alias: 'c'
		}
		{
 			signature: 'email'
 			parameter: 'email'
 			description: 'email'
 			alias: [ 'e', 'u' ]
 		}
 		{
 			signature: 'password'
 			parameter: 'password'
 			description: 'password'
 			alias: 'p'
 		}
	]
	primary: true
	action: (params, options, done) ->
		_ = require('lodash')
		Promise = require('bluebird')
		resin = require('resin-sdk').fromSharedOptions()
		auth = require('../auth')
		form = require('resin-cli-form')
		patterns = require('../utils/patterns')
		messages = require('../utils/messages')

		login = (options) ->
			if options.token?
				return Promise.try ->
					return options.token if _.isString(options.token)
					return form.ask
						message: 'Session token or API key (experimental) from the preferences page'
						name: 'token'
						type: 'input'
				.then(resin.auth.loginWithToken)
				.tap ->
					resin.auth.whoami()
					.then (username) ->
						if !username
							patterns.exitWithExpectedError('Token authentication failed')
			else if options.credentials
				return patterns.authenticate(options)
			else if options.web
				console.info('Connecting to the web dashboard')
				return auth.login()

			return patterns.askLoginType().then (loginType) ->

				if loginType is 'register'
					{ runCommand } = require('../utils/helpers')
					return runCommand('signup')

				options[loginType] = true
				return login(options)

		resin.settings.get('resinUrl').then (resinUrl) ->
			console.log(messages.resinAsciiArt)
			console.log("\nLogging in to #{resinUrl}")
			return login(options)
		.then(resin.auth.whoami)
		.tap (username) ->
			console.info("Successfully logged in as: #{username}")
			console.info """

				Find out about the available commands by running:

				  $ resin help

				#{messages.reachingOut}
			"""
		.nodeify(done)

exports.logout =
	signature: 'logout'
	description: 'logout from resin.io'
	help: '''
		Use this command to logout from your resin.io account.o

		Examples:

			$ resin logout
	'''
	action: (params, options, done) ->
		resin = require('resin-sdk-preconfigured')
		resin.auth.logout().nodeify(done)

exports.signup =
	signature: 'signup'
	description: 'signup to resin.io'
	help: '''
		Use this command to signup for a resin.io account.

		If signup is successful, you'll be logged in to your new user automatically.

		Examples:

			$ resin signup
			Email: johndoe@acme.com
			Password: ***********

			$ resin whoami
			johndoe
	'''
	action: (params, options, done) ->
		resin = require('resin-sdk-preconfigured')
		form = require('resin-cli-form')
		validation = require('../utils/validation')

		resin.settings.get('resinUrl').then (resinUrl) ->
			console.log("\nRegistering to #{resinUrl}")

			form.run [
				message: 'Email:'
				name: 'email'
				type: 'input'
				validate: validation.validateEmail
			,
				message: 'Password:'
				name: 'password'
				type: 'password',
				validate: validation.validatePassword
			]

		.then(resin.auth.register)
		.then(resin.auth.loginWithToken)
		.nodeify(done)

exports.whoami =
	signature: 'whoami'
	description: 'get current username and email address'
	help: '''
		Use this command to find out the current logged in username and email address.

		Examples:

			$ resin whoami
	'''
	permission: 'user'
	action: (params, options, done) ->
		Promise = require('bluebird')
		resin = require('resin-sdk').fromSharedOptions()
		visuals = require('resin-cli-visuals')

		Promise.props
			username: resin.auth.whoami()
			email: resin.auth.getEmail()
			url: resin.settings.get('resinUrl')
		.then (results) ->
			console.log visuals.table.vertical results, [
				'$account information$'
				'username'
				'email'
				'url'
			]
		.nodeify(done)
