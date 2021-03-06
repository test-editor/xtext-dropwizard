package org.testeditor.web.xtext.index.changes

import com.google.inject.Inject
import java.io.File
import javax.inject.Singleton
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.jgit.diff.DiffEntry
import org.slf4j.LoggerFactory
import org.testeditor.web.xtext.index.ChangeDetector
import org.testeditor.web.xtext.index.ChangedResources
import org.testeditor.web.xtext.index.persistence.GitService

@Singleton
class GitBasedChangeDetector implements ChangeDetector {

	static val logger = LoggerFactory.getLogger(GitBasedChangeDetector)
	public static val String SUCCESSOR_NAME = 'GitBasedChangeDetectorSuccessor'

	@Inject GitService git

	var String lastUpdatedAtRevision = null

	override reset() {
		lastUpdatedAtRevision = null
		return this
	}

	override ChangedResources detectChanges(ResourceSet resourceSet, String[] paths, ChangedResources accumulatedChanges) {
		val root = git.projectFolder
		pullAndGetDiff.fold(accumulatedChanges, [ changedResources, diff |
			changedResources.handleDiff(diff, root, resourceSet)
		])
		return accumulatedChanges
	}

	private def pullAndGetDiff() {
		val oldHead = lastUpdatedAtRevision
		git.pull
		lastUpdatedAtRevision = git.headTree.name()
		return if (oldHead === null) {
			git.allFilesAsDiff(lastUpdatedAtRevision)
		} else {
			git.calculateDiff(oldHead, lastUpdatedAtRevision)
		}
	}

	private def ChangedResources handleDiff(ChangedResources changedResources, DiffEntry diff, File root, ResourceSet resourceSet) {
		logger.debug("Handling Git diff='{}'.", diff)
		return changedResources => [
			switch (diff.changeType) {
				case ADD,
				case MODIFY,
				case COPY: {
					modifiedResources += getAbsoluteFileURI(root, diff.newPath)
				}
				case DELETE: {
					deletedResources += getAbsoluteFileURI(root, diff.oldPath)
				}
				case RENAME: {
					deletedResources += getAbsoluteFileURI(root, diff.oldPath)
					modifiedResources += getAbsoluteFileURI(root, diff.newPath)
				}
				default: {
					throw new RuntimeException('''Unknown Git diff change type='«diff.changeType.name»'.''')
				}
			}
		]
	}

	private def URI getAbsoluteFileURI(File file) {
		return URI.createFileURI(file.absolutePath)
	}

	private def URI getAbsoluteFileURI(File parent, String child) {
		val file = new File(parent, child)
		return getAbsoluteFileURI(file)
	}

}
