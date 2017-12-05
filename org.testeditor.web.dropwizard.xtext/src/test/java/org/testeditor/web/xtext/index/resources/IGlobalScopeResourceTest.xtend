package org.testeditor.web.xtext.index.resources

import com.fasterxml.jackson.databind.module.SimpleModule
import com.squarespace.jersey2.guice.JerseyGuiceUtils
import io.dropwizard.testing.junit.ResourceTestRule
import java.util.List
import javax.ws.rs.Consumes
import javax.ws.rs.POST
import javax.ws.rs.Path
import javax.ws.rs.Produces
import javax.ws.rs.QueryParam
import javax.ws.rs.client.Entity
import javax.ws.rs.core.GenericType
import javax.ws.rs.core.Response
import org.eclipse.emf.ecore.util.EcoreUtil
import org.eclipse.xtext.XtextFactory
import org.eclipse.xtext.XtextPackage
import org.eclipse.xtext.naming.QualifiedName
import org.eclipse.xtext.resource.EObjectDescription
import org.eclipse.xtext.resource.IEObjectDescription
import org.junit.Before
import org.junit.BeforeClass
import org.junit.Rule
import org.junit.Test
import org.testeditor.web.xtext.index.serialization.EObjectDescriptionDeserializer
import org.testeditor.web.xtext.index.serialization.EObjectDescriptionSerializer

import static org.assertj.core.api.Assertions.assertThat

/**
 * Tests whether the interface can be successfully invoked via its exposed REST
 * endpoint.
 *
 * The test uses the Xtext language as illustrative example.
 * 
 * The value of this test is the working test setup in the face of guice issues 
 * using the ResourceTestRule as testbed (instead of more heavyweight tests using
 * the DropwizardAppRule)!
 */
class IGlobalScopeResourceTest {

	/**
	 * Workaround related to the following dropwizard / dropwizard-guice / jersey2-guice issues
	 * https://github.com/dropwizard/dropwizard/issues/1772
	 * https://github.com/HubSpot/dropwizard-guice/issues/95
	 * https://github.com/HubSpot/dropwizard-guice/issues/88
	 * https://github.com/Squarespace/jersey2-guice/pull/39
	 */
	@BeforeClass
	static def void ensureServiceLocatorPopulated() {
		JerseyGuiceUtils.reset();
	}

	private val resourceUnderTest = new DummyGlobalScopeResource

	@Rule public val resources = ResourceTestRule.builder.addResource(resourceUnderTest).build

	@Before
	def void registerCustomSerializers() {
		val customSerializerModule = new SimpleModule
		customSerializerModule.addSerializer(IEObjectDescription, new EObjectDescriptionSerializer())
		customSerializerModule.addDeserializer(IEObjectDescription, new EObjectDescriptionDeserializer())
		resources.objectMapper.registerModule(customSerializerModule)
	}

	@Test
	def void shouldTransmitViaREST() {
		// given
		val context = '''
			grammar org.xtext.example.mydsl.MyDsl with org.eclipse.xtext.common.Terminals

			generate myDsl "http://www.xtext.org/example/mydsl/MyDsl"

			Model:
				greetings+=Greeting*;

			Greeting:
				'Hello' name=ID '!';
		'''
		val contentType = "xtext"
		val contextURI = "mydsl.xtext"
		// "http://www.eclipse.org/2008/Xtext#//Grammar/usedGrammars"
		val reference = EcoreUtil.getURI(XtextPackage.eINSTANCE.grammar_UsedGrammars).toString

		// when
		val actual = resources.target("/xtext/index/global-scope") //
		.queryParam("reference", reference) //
		.queryParam("contentType", contentType) //
		.queryParam("contextURI", contextURI) //
		.request //
		.post(Entity.text(context), new GenericType<List<IEObjectDescription>> {
		})

		// then
		assertThat(actual).size.isEqualTo(1)
		val expectedResponse = EObjectDescription.create(QualifiedName.create("de", "testeditor", "ExampleGrammar"),
			XtextFactory.eINSTANCE.createGrammar)
		assertThat(actual).allSatisfy [
			assertThat(EObjectURI).isEqualTo(expectedResponse.EObjectURI)
			assertThat(EClass).isEqualTo(expectedResponse.EClass)
			assertThat(qualifiedName.toString).isEqualTo(expectedResponse.qualifiedName.toString)
		]
		assertThat(resourceUnderTest).satisfies [ actuallyReceived |
			assertThat(actuallyReceived.context).isEqualTo(context)
			assertThat(actuallyReceived.eReferenceURIString).isEqualTo(reference)
			assertThat(actuallyReceived.contentType).isEqualTo(contentType)
			assertThat(actuallyReceived.contextURI).isEqualTo(contextURI)
		]

	}
}

@Path("/xtext/index/global-scope")
class DummyGlobalScopeResource implements GlobalScopeResource {
	public String context = null
	public String eReferenceURIString = null
	public String contentType = null
	public String contextURI = null

	@POST
	@Consumes("text/plain")
	@Produces("application/json")
	override Response getScope(String context, @QueryParam("contentType") String contentType,
		@QueryParam("contextURI") String contextURI, @QueryParam("reference") String eReferenceURIString) {
		this.context = context
		this.contentType = contentType
		this.contextURI = contextURI
		this.eReferenceURIString = eReferenceURIString

		val description = EObjectDescription.create(QualifiedName.create("de", "testeditor", "ExampleGrammar"),
			XtextFactory.eINSTANCE.createGrammar)

		return Response.ok(#[description]).build
	}

}
