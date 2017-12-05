package org.testeditor.web.xtext.index.persistence

import java.io.File
import java.util.List
import javax.inject.Singleton
import org.eclipse.jgit.api.Git
import org.eclipse.jgit.diff.DiffEntry
import org.eclipse.jgit.lib.ObjectId
import org.eclipse.jgit.treewalk.CanonicalTreeParser
import org.slf4j.LoggerFactory
import com.google.common.annotations.VisibleForTesting

/**
 * provide some service around a git repo (read only)
 */
@Singleton
class GitService {
	
	static val logger = LoggerFactory.getLogger(GitService)

	protected Git git = null

	/** 
	 * initialize this git service. either open the existing git and pull, or clone the remote repo
	 */
	def void init(File projectFolder, String uriString) {
		if (projectFolder.exists && projectFolder.isDirectory && (projectFolder.listFiles.map[name].contains(".git"))) {
			openRepository(projectFolder)
			pull
		} else {
			cloneRepository(projectFolder, uriString)
		}
	}

	/**
	 * pull from remote
	 */
	def void pull() {
		git.pull.call

	}

	/** 
	 * calculate diff between these two commits
	 */
	def List<DiffEntry> calculateDiff(String oldHeadCommit, String newHeadCommit) {
		return calculateDiff(ObjectId.fromString(oldHeadCommit), ObjectId.fromString(newHeadCommit))
	}

	private def List<DiffEntry> calculateDiff(ObjectId oldHead, ObjectId newHead) {
		logger.info("Calculating diff between old='{}' and new='{}'.", oldHead.getName, newHead.getName)
		val reader = git.repository.newObjectReader
		try {
			val oldTree = new CanonicalTreeParser => [reset(reader, oldHead)]
			val newTree = new CanonicalTreeParser => [reset(reader, newHead)]
			val diff = git.diff.setOldTree(oldTree).setNewTree(newTree).call
			logger.info("Calculated diff='{}'.", diff)
			return diff
		} finally {
			reader.close
		}
	}

	private def void cloneRepository(File projectFolder, String uriString) {
		git = Git.cloneRepository.setDirectory(projectFolder).setURI(uriString).call
	}

	@VisibleForTesting
	protected def void openRepository(File projectFolder) {
		git = Git.open(projectFolder)
	}

}
