package org.testeditor.web.xtext.index

import com.auth0.jwt.JWT
import com.auth0.jwt.algorithms.Algorithm
import com.fasterxml.jackson.core.type.TypeReference
import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.databind.module.SimpleModule
import com.google.inject.Guice
import com.google.inject.util.Modules
import io.dropwizard.testing.ResourceHelpers
import io.dropwizard.testing.junit.DropwizardAppRule
import java.io.File
import java.io.InputStream
import java.util.List
import javax.ws.rs.client.Entity
import javax.ws.rs.client.Invocation
import javax.ws.rs.core.Response
import org.eclipse.emf.common.util.URI
import org.eclipse.jgit.junit.JGitTestUtil
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtext.resource.IEObjectDescription
import org.junit.After
import org.junit.Before
import org.junit.ClassRule
import org.junit.Rule
import org.junit.rules.TemporaryFolder
import org.testeditor.aml.dsl.AmlStandaloneSetup
import org.testeditor.tcl.dsl.TclStandaloneSetup
import org.testeditor.tsl.dsl.TslRuntimeModule
import org.testeditor.tsl.dsl.web.TslWebSetup
import org.testeditor.web.xtext.index.serialization.EObjectDescriptionDeserializer

import static io.dropwizard.testing.ConfigOverride.config

class AbstractIntegrationTest {

	public static class TestXtextIndexApplication extends XtextIndexApplication {
		val injector = Guice.createInjector(Modules.override(new TslRuntimeModule).with(new XtextIndexModule))
		@Accessors(PUBLIC_GETTER)
		val index = injector.getInstance(XtextIndex) // construct index with language injector

		override getLanguageSetups() {
			return #[new TslWebSetup, new TclStandaloneSetup, new AmlStandaloneSetup]
		}

		override getGuiceInjector() {
			return injector
		}

	}

	@ClassRule
	public static val temporaryFolder = new TemporaryFolder

	@Rule
	public val dropwizardRule = new DropwizardAppRule(TestXtextIndexApplication,
		ResourceHelpers.resourceFilePath("config.yml"), #[
			config('localRepoFileRoot', temporaryFolder.root.absolutePath),
			config('logging.level', 'INFO')
		])

	protected var ObjectMapper objectMapper

	@Before
	public def void initObjectMapper() {
		val jacksonModule = new SimpleModule
		jacksonModule.addDeserializer(IEObjectDescription, new EObjectDescriptionDeserializer)
		objectMapper = dropwizardRule.environment.objectMapper.registerModule(jacksonModule)
	}

	protected def void addFileToIndex(String fileName, String content) {
		val file = new File(temporaryFolder.root, fileName)
		JGitTestUtil.write(file, content)
		(dropwizardRule.application as TestXtextIndexApplication).index.add(URI.createFileURI(file.absolutePath))
	}

	def void addSeparateMacroCollectionToIndexTimes(int size) {
		for (counter : 0 ..< size) {
			addFileToIndex(
				'''pack/MacroLib«counter».tml''',
				'''
					package pack
					
					# MacroLib«counter»
					
					## Macro«counter»
					
						template = "code«counter»"
					
						Component: SomeComponent
						- Some fixture call
				'''
			)
		}
	}

	@After
	public def void cleanupTempFolder() {
		// since temporary folder is a class rule (to make sure it is run before the dropwizard rule),
		// cleanup all contents of the temp folder without deleting it itself
		recursiveDelete(temporaryFolder.root, false)
	}

	protected def String getToken() {
		val builder = JWT.create => [
			withClaim('id', 'john.doe')
			withClaim('name', 'John Doe')
			withClaim('email', 'john@example.org')
		]
		return builder.sign(Algorithm.HMAC256("secret"))
	}

	protected def Invocation.Builder authHeader(Invocation.Builder builder) {
		builder.header('Authorization', '''Bearer «token»''')
		return builder
	}

	protected def void recursiveDelete(File file, boolean deleteThis) {
		file.listFiles?.forEach[recursiveDelete(true)]
		if (deleteThis) {
			file.delete
		}
	}

	protected def Response postGlobalScopeRequest(String context, String reference, String contentType,
		String contextURI) {

		return dropwizardRule.client //
		.target('''http://localhost:«dropwizardRule.localPort»/xtext/index/global-scope''') //
		.queryParam("reference", reference) //
		.queryParam("contentType", contentType) //
		.queryParam("contextURI", contextURI) //
		.request //
		.authHeader //
		.post(Entity.text(context))
	}

	protected def List<IEObjectDescription> deserializeIEObjectDescriptions(InputStream payload) {
		return objectMapper.<List<IEObjectDescription>>readValue(payload,
			new TypeReference<List<IEObjectDescription>>() {
			})
	}

	protected def Exception deserializeException(InputStream payload) {
		return objectMapper.<Exception>readValue(payload, Exception)
	}
}
