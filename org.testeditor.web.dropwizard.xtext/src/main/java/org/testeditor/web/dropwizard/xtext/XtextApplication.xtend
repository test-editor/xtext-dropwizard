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
import org.testeditor.web.xtext.index.IndexResource
import org.testeditor.web.xtext.index.IndexSearchPathProvider
import org.testeditor.web.xtext.index.XtextIndexModule
import org.testeditor.web.xtext.index.changes.IndexFilterModule
import org.testeditor.web.xtext.index.changes.TestEditorChangeDetector
import org.testeditor.web.xtext.index.persistence.GitService

abstract class XtextApplication<T extends XtextConfiguration> extends DropwizardApplication<T> {

	@Inject XtextIndexModule indexModule
	@Inject GitService gitService
	@Inject BuildCycleManager buildManager
	
	var T config

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
			// IWebResourceSetProvider is used by Xtext servlet requests to build resource sets (created and) used for a single request
			// (see XtextServiceDispatcher line 204 [org.eclipse.xtext.web:2.13.0]) binder.bind(IWebResourceSetProvider).to(CustomWebResourceSetProvider)
			binder.bind(IWebResourceSetProvider).to(CustomWebResourceSetProvider)
			
			// A binding from the actual configuration type to the proper instance is added by the GuiceBundle.
			// However, classes that expect an XtextConfiguration object to be injected will not receive that
			// instance, because Guice does not traverse the subtype hierarchy that way. Therefore, a binding
			// for the base class is added here, unless the configuration class was not subtyped, in which case
			// the binding provided by the GuiceBundle will cover this (and another binding would yield a conflict).
			val bindConfigurationToSubtypedConfiguration = (this.configurationClass !== XtextConfiguration)
			if (bindConfigurationToSubtypedConfiguration) {
				binder.bind(XtextConfiguration).toProvider[config]
			}

		]
		modules += new XtextRuntimeModule

	}

	override run(T configuration, Environment environment) throws Exception {
		super.run(configuration, environment)
		this.config = configuration

		// necessary for jackson json serializer to ignore transient fields (in xtext ContentAssistEntry)
		// see ExampleXtextApplicationIntegrationTest.serializingContentAssistEntryWorksEvenIfEObjectIsPresent and https://stackoverflow.com/a/38956032/1839228
		environment.objectMapper.enable(MapperFeature.PROPAGATE_TRANSIENT_MARKER)

		initializeXtextIndex(environment)
		configureXtextServiceResource(environment)
		configureIndexResource(environment)
		configureValidationMarkerResource(environment)
	}

	protected def void initializeXtextIndex(Environment environment) {
		gitService.init(config.localRepoFileRoot, config.remoteRepoUrl, config.privateKeyLocation, config.knownHostsLocation)
		buildManager.startBuild
	}

	protected def void configureXtextServiceResource(Environment environment) {
		environment.servlets.sessionHandler = new SessionHandler
		environment.jersey.register(XtextServiceResource)
	}

	protected def void configureIndexResource(Environment environment) {
		environment.jersey.register(IndexResource)
	}

	protected def void configureValidationMarkerResource(Environment environment) {
		environment.jersey.register(ValidationMarkerResource)
	}

	/**
	 * Users of this class are expected to return a list of language setups with this
	 * method. If the language requires an Xtext index, the passed module must be
	 * integrated during injector creation.
	 */
	abstract protected def List<ISetup> getLanguageSetups(XtextIndexModule indexModule)

}
