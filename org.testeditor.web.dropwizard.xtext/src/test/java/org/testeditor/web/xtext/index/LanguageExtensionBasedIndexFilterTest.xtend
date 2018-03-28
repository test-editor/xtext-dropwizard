package org.testeditor.web.xtext.index

import org.junit.Test
import org.mockito.InjectMocks
import org.mockito.Mock
import org.testeditor.web.xtext.index.changes.LanguageExtensionBasedIndexFilter

import static org.mockito.Mockito.when

import static extension org.eclipse.emf.common.util.URI.createFileURI

class LanguageExtensionBasedIndexFilterTest extends AbstractTestWithExampleLanguage {
	@Mock LanguageAccessRegistry languages
	@InjectMocks LanguageExtensionBasedIndexFilter languageExtensionFilterUnderTest 
	
	@Test
	def void testIsRelevantForIndex() {
		// given
		val testData = #[
			'test.mydsl' -> true,
			'test.MYDSL' -> true,
			'test.mydsl.txt' -> false,
			'test.xml' -> false,
			null -> false,
			'' -> false
		]
		when(languages.extensions).thenReturn(#['mydsl'])
		
		testData.forEach[
			// when
			val isRelevant = languageExtensionFilterUnderTest.isRelevantForIndex(key?.createFileURI)

			// then
			isRelevant.assertEquals(value)			
		]
	}
}