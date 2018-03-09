package org.testeditor.web.xtext.index

import org.junit.Test
import org.testeditor.web.xtext.index.changes.LanguageExtensionBasedIndexFilter

class LanguageExtensionBasedIndexFilterTest extends AbstractTestWithExampleLanguage {
	val unitUnderTest = new LanguageExtensionBasedIndexFilter
	
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
		testData.forEach[
			// when
			val isRelevant = unitUnderTest.isRelevantForIndex(key)

			// then
			isRelevant.assertEquals(value)			
		]
	}
}