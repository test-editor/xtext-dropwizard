package org.testeditor.web.dropwizard.xtext

import com.fasterxml.jackson.databind.MapperFeature
import com.google.inject.Module
import io.dropwizard.setup.Bootstrap
import io.dropwizard.setup.Environment
import java.io.File
import java.util.List
import javax.inject.Inject
import org.eclipse.jetty.server.session.SessionHandler
import org.eclipse.xtext.ISetup
import org.eclipse.xtext.XtextRuntimeModule
import org.eclipse.xtext.common.TerminalsStandaloneSetup
import org.testeditor.web.dropwizard.DropwizardApplication
import org.testeditor.web.xtext.index.XtextIndexModule
import org.testeditor.web.xtext.index.persistence.GitService
import org.testeditor.web.xtext.index.persistence.IndexUpdater
import org.testeditor.web.xtext.index.persistence.webhook.BitbucketWebhookResource

abstract class XtextApplication<T extends XtextConfiguration> extends DropwizardApplication<T> {

	@Inject XtextIndexModule indexModule
	@Inject GitService gitService
	@Inject IndexUpdater indexUpdater

	override protected initializeInjection(Bootstrap<T> bootstrap) {
		new TerminalsStandaloneSetup().createInjectorAndDoEMFRegistration
		super.initializeInjection(bootstrap)
	}

	override protected collectModules(List<Module> modules) {
		super.collectModules(modules)
		modules += new XtextRuntimeModule
	}

	override run(T configuration, Environment environment) throws Exception {
		super.run(configuration, environment)

		// necessary for jackson json serializer to ignore transient fields (in xtext ContentAssistEntry)
		// see ExampleXtextApplicationIntegrationTest.serializingContentAssistEntryWorksEvenIfEObjectIsPresent and https://stackoverflow.com/a/38956032/1839228
		environment.objectMapper.enable(MapperFeature.PROPAGATE_TRANSIENT_MARKER)

		runLanguageSetups(configuration, environment)
		initializeXtextIndex(configuration, environment)
		configureXtextServiceResource(configuration, environment)
		configureWebhooks(configuration, environment)
	}

	protected def void runLanguageSetups(T configuration, Environment environment) {
		val setups = getLanguageSetups(indexModule)
		indexUpdater.setLanguageSetups(setups)
		setups.forEach[createInjectorAndDoEMFRegistration()]
	}

	protected def void initializeXtextIndex(T configuration, Environment environment) {
		gitService.init(configuration.localRepoFileRoot, configuration.remoteRepoUrl, configuration.privateKeyLocation, configuration.knownHostsLocation)
		indexUpdater.initIndexWithGradleRoot(new File(configuration.localRepoFileRoot))
	}

	protected def void configureXtextServiceResource(T configuration, Environment environment) {
		environment.servlets.sessionHandler = new SessionHandler
		environment.jersey.register(XtextServiceResource)
	}

	protected def void configureWebhooks(T configuration, Environment environment) {
		environment.jersey.register(BitbucketWebhookResource)
	}

	/**
	 * Users of this class are expected to return a list of language setups with this
	 * method. If the language requires an Xtext index, the passed module must be
	 * integrated during injector creation.
	 */
	abstract protected def List<ISetup> getLanguageSetups(XtextIndexModule indexModule)

}
