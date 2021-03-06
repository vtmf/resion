import { CommandDefinition } from 'capitano';
import { stripIndent } from 'common-tags';

export const generate: CommandDefinition<{
	name: string;
}> = {
	signature: 'api-key generate <name>',
	description: 'Generate a new API key with the given name',
	help: stripIndent`
		This command generates a new API key for the current user, with the given
		name. The key will be logged to the console.

		This key can be used to log into the CLI using 'resin login --token <key>',
		or to authenticate requests to the API with an 'Authorization: Bearer <key>' header.

		Examples:

			$ resin api-key generate "Jenkins Key"
	`,
	async action(params, _options, done) {
		const resin = (await import('resin-sdk')).fromSharedOptions();

		resin.models.apiKey
			.create(params.name)
			.then(key => {
				console.log(stripIndent`
					Registered api key '${params.name}':

					${key}

					This key will not be shown again, so please save it now.
				`);
			})
			.finally(done);
	},
};
