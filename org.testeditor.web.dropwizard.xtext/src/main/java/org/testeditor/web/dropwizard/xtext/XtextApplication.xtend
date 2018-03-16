package org.testeditor.web.dropwizard.xtext

import com.fasterxml.jackson.databind.MapperFeature
import com.google.inject.Module
import com.google.inject.TypeLiteral
import io.dropwizard.setup.Bootstrap
import io.dropwizard.setup.Environment
import java.util.List
import javax.inject.Inject
import javax.ws.rs.core.Response
import javax.ws.rs.core.Response.ResponseBuilder
import org.eclipse.jetty.server.session.SessionHandler
import org.eclipse.xtext.ISetup
import org.eclipse.xtext.XtextRuntimeModule
import org.eclipse.xtext.builder.standalone.IIssueHandler
import org.eclipse.xtext.common.TerminalsStandaloneSetup
import org.eclipse.xtext.resource.IContainer
import org.eclipse.xtext.resource.IResourceDescriptionsProvider
import org.eclipse.xtext.resource.containers.ProjectDescriptionBasedContainerManager
import org.eclipse.xtext.web.server.model.IWebResourceSetProvider
import org.testeditor.web.dropwizard.DropwizardApplication
import org.testeditor.web.dropwizard.xtext.validation.ValidationMarkerResource
import org.testeditor.web.dropwizard.xtext.validation.ValidationMarkerUpdater
import org.testeditor.web.xtext.index.BuildCycleManager
import org.testeditor.web.xtext.index.ChangeDetector
import org.testeditor.web.xtext.index.ChunkedResourceDescriptionsProvider
import org.testeditor.web.xtext.index.CustomWebResourceSetProvider
import org.testeditor.web.xtext.index.IndexSearchPathProvider
import org.testeditor.web.xtext.index.XtextIndexModule
import org.testeditor.web.xtext.index.changes.IndexFilterModule
import org.testeditor.web.xtext.index.changes.TestEditorChangeDetector
import org.testeditor.web.xtext.index.persistence.GitService
import org.testeditor.web.xtext.index.persistence.webhook.BitbucketWebhookResource

abstract class XtextApplication<T extends XtextConfiguration> extends DropwizardApplication<T> {

	@Inject XtextIndexModule indexModule
	@Inject GitService gitService
	@Inject ValidationMarkerUpdater validationMarkerUpdater
	@Inject BuildCycleManager buildManager

	override protected initializeInjection(Bootstrap<T> bootstrap) {
		new TerminalsStandaloneSetup().createInjectorAndDoEMFRegistration
		super.initializeInjection(bootstrap)
	}

	override protected collectModules(List<Module> modules) {
		super.collectModules(modules)
		modules += [ binder |
			binder.install(new IndexFilterModule)

			binder.bind(ChangeDetector).to(TestEditorChangeDetector)
			binder.bind(IIssueHandler).to(ValidationMarkerUpdater)
			binder.bind(ResponseBuilder).toProvider[Response.ok]
			binder.bind(new TypeLiteral<Iterable<ISetup>>() {}).toProvider[getLanguageSetups(indexModule)]
			binder.bind(IndexSearchPathProvider).toInstance[#[]]
			binder.bind(IContainer.Manager).to(ProjectDescriptionBasedContainerManager)
			binder.bind(IResourceDescriptionsProvider).to(ChunkedResourceDescriptionsProvider)
			binder.bind(IWebResourceSetProvider).to(CustomWebResourceSetProvider)
		]
		modules += new XtextRuntimeModule

	}

	override run(T configuration, Environment environment) throws Exception {
		super.run(configuration, environment)

		// necessary for jackson json serializer to ignore transient fields (in xtext ContentAssistEntry)
		// see ExampleXtextApplicationIntegrationTest.serializingContentAssistEntryWorksEvenIfEObjectIsPresent and https://stackoverflow.com/a/38956032/1839228
		environment.objectMapper.enable(MapperFeature.PROPAGATE_TRANSIENT_MARKER)

		initializeXtextIndex(configuration, environment)
		configureXtextServiceResource(configuration, environment)
		configureWebhooks(configuration, environment)
		configureValidationMarkerResource(configuration, environment)
	}

	protected def void initializeXtextIndex(T configuration, Environment environment) {
		gitService.init(configuration.localRepoFileRoot, configuration.remoteRepoUrl, configuration.privateKeyLocation,
			configuration.knownHostsLocation)
		validationMarkerUpdater.init(configuration.localRepoFileRoot)
		buildManager.startBuild
	}

	protected def void configureXtextServiceResource(T configuration, Environment environment) {
		environment.servlets.sessionHandler = new SessionHandler
		environment.jersey.register(XtextServiceResource)
	}

	protected def void configureWebhooks(T configuration, Environment environment) {
		environment.jersey.register(BitbucketWebhookResource)
	}

	protected def void configureValidationMarkerResource(T configuration, Environment environment) {
		environment.jersey.register(ValidationMarkerResource)
	}

	/**
	 * Users of this class are expected to return a list of language setups with this
	 * method. If the language requires an Xtext index, the passed module must be
	 * integrated during injector creation.
	 */
	abstract protected def List<ISetup> getLanguageSetups(XtextIndexModule indexModule)

}
