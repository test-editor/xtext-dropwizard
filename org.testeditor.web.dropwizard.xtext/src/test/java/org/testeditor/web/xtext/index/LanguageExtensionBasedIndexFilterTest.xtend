package org.testeditor.web.xtext.index

import org.junit.Test
import org.mockito.InjectMocks
import org.testeditor.web.xtext.index.changes.LanguageExtensionBasedIndexFilter
import org.mockito.Mock
import static org.mockito.Mockito.when

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
			val isRelevant = languageExtensionFilterUnderTest.isRelevantForIndex(key)

			// then
			isRelevant.assertEquals(value)			
		]
	}
}