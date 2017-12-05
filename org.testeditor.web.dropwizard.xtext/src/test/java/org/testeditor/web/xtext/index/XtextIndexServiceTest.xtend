package org.testeditor.web.xtext.index

import com.google.inject.Injector
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.EPackage
import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.ecore.util.EcoreUtil
import org.eclipse.xtext.XtextPackage
import org.eclipse.xtext.XtextStandaloneSetup
import org.eclipse.xtext.mwe.ResourceDescriptionsProvider
import org.eclipse.xtext.resource.XtextResourceSet
import org.junit.Before
import org.junit.Test

import static org.assertj.core.api.Assertions.assertThat

class XtextIndexServiceTest {

	var Injector injector

	@Before
	def void setupXtextInjector() {
		injector = new XtextStandaloneSetup().createInjectorAndDoEMFRegistration
	}

	@Test
	def void shouldLoadResourceIntoIndex() {
		// given
		val resourceSet = injector.getInstance(XtextResourceSet)
		resourceSet.getResource(URI.createFileURI("src/test/resources/index/MyDsl.xtext"), true)
		val expectedExportedObjectName = 'org.xtext.example.mydsl.MyDsl'

		// when
		val index = injector.getInstance(ResourceDescriptionsProvider).get(resourceSet)

		// then
		assertThat(index.exportedObjects.map[name.toString]).contains(expectedExportedObjectName)
	}

	@Test
	def void shouldReturnEPackageByName() {
		// given
		val ePackage = EPackage.Registry.INSTANCE.getEPackage("http://www.eclipse.org/2008/Xtext")
		val expectedEReferenceNameContainedInXtextGrammar = 'usedGrammars'

		// when
		val grammar = ePackage.getEClassifier("Grammar")

		// then
		assertThat(grammar.eCrossReferences.filter(EReference).map[name]).contains(
			expectedEReferenceNameContainedInXtextGrammar)
	}

	@Test
	def void shouldBeReconstructibleFromURI() {
		// given
		val usedGrammersEReferenceURI = EcoreUtil.getURI(XtextPackage.eINSTANCE.grammar_UsedGrammars)

		// when
		val ePackageOfUsedGrammars = EPackage.Registry.INSTANCE.getEPackage(usedGrammersEReferenceURI.trimFragment.toString)
		val actualEObject = ePackageOfUsedGrammars.eResource.getEObject(usedGrammersEReferenceURI.fragment)

		// then
		assertThat(actualEObject).isInstanceOf(EReference) 
		assertThat((actualEObject as EReference).name).isEqualTo("usedGrammars")
		assertThat(actualEObject).isSameAs(XtextPackage.eINSTANCE.grammar_UsedGrammars)
	}

}
