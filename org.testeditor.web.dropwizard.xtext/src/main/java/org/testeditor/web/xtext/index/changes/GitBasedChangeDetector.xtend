package org.testeditor.web.xtext.index.changes

import java.io.File
import javax.inject.Inject
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.jgit.diff.DiffEntry
import org.slf4j.LoggerFactory
import org.testeditor.web.xtext.index.ChangeDetector
import org.testeditor.web.xtext.index.ChangedResources
import org.testeditor.web.xtext.index.SetBasedChangedResources
import org.testeditor.web.xtext.index.persistence.GitService

class GitBasedChangeDetector implements ChangeDetector {

	static val logger = LoggerFactory.getLogger(GitBasedChangeDetector)

	@Inject GitService git
	@Inject extension IndexFilter indexFilter

	override ChangedResources detectChanges(ResourceSet resourceSet, String[] paths) {
		val root = git.projectFolder
		return pullAndGetDiff.filter[oldPath.isRelevantForIndex || newPath.isRelevantForIndex].fold(
			new SetBasedChangedResources, [ changedResources, diff |
				changedResources.handleRelevantDiff(diff, root, resourceSet)
			])
	}

	private def pullAndGetDiff() {
		val oldHead = git.headTree.name()
		git.pull
		return git.calculateDiff(oldHead, git.headTree.name())
	}

	private def SetBasedChangedResources handleRelevantDiff(SetBasedChangedResources changedResources, DiffEntry diff,
		File root, ResourceSet resourceSet) {
		logger.debug("Handling Git diff='{}'.", diff)
		return changedResources => [
			switch (diff.changeType) {
				case ADD,
				case MODIFY: {
					modifiedResources += getAbsoluteFileURI(root, diff.newPath)
				}
				case COPY: {
					if (diff.newPath.isRelevantForIndex) {
						modifiedResources += getAbsoluteFileURI(root, diff.newPath)
					} else {
						logger.debug("Skipping index update for irrelevant diff='{}'.", diff)
					}
				}
				case DELETE: {
					deletedResources += getAbsoluteFileURI(root, diff.oldPath)
				}
				case RENAME: {
					if (diff.oldPath.isRelevantForIndex) {
						deletedResources += getAbsoluteFileURI(root, diff.oldPath)
					}
					if (diff.newPath.isRelevantForIndex) {
						modifiedResources += getAbsoluteFileURI(root, diff.newPath)
					}
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
