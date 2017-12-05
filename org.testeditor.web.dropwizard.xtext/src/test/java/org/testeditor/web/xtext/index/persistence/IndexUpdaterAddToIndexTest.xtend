package org.testeditor.web.xtext.index.persistence

import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import org.mockito.InjectMocks
import org.mockito.Mock
import org.testeditor.web.xtext.index.AbstractTestWithExampleLanguage
import org.testeditor.web.xtext.index.XtextIndex

import static extension org.eclipse.emf.common.util.URI.createFileURI
import static extension org.mockito.Mockito.*

class IndexUpdaterAddToIndexTest extends AbstractTestWithExampleLanguage {

	@Rule public TemporaryFolder tmpFolder = new TemporaryFolder

	@InjectMocks IndexUpdater indexUpdater
	@Mock XtextIndex index

	@Test
	def void initializesIndexCorrectly() {
		// given
		val example = tmpFolder.newFile('example.mydsl')
		tmpFolder.newFolder('subfolder')
		val relevant = tmpFolder.newFile('subfolder/relevant.MYDSL')
		tmpFolder.newFile('subfolder/irrelevant.md')

		// files below .git folder
		tmpFolder.newFolder('.git')
		tmpFolder.newFile('.git/shouldNotBeIndexed.mydsl')

		// when
		indexUpdater.addToIndex(tmpFolder.root)

		// then
		val exampleUri = example.absolutePath.createFileURI
		val relevantUri = relevant.absolutePath.createFileURI
		index.verify.updateOrAdd(exampleUri)
		index.verify.updateOrAdd(relevantUri)
		verifyNoMoreInteractions(index)
	}

}
