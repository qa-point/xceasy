/// Utility for working with step hierarchies
public class StepUtils {

    /// Finds the last failed step in the step hierarchy
    ///
    /// - Parameter steps: Array of steps to search
    /// - Returns: The last failed step if found
    internal static func findLastFailedStep(in steps: [StepResult]) -> StepResult? {
        for step in steps.reversed() {
            if step.status == .failed || step.status == .broken {
                return step
            }

            if let nestedSteps = step.steps, let failedNestedStep = findLastFailedStep(in: nestedSteps) {
                return failedNestedStep
            }
        }
        return nil
    }

    /// Attaches attachment to the last failed step in hierarchy and returns modified steps
    ///
    /// - Parameters:
    ///   - steps: Step hierarchy
    ///   - attachment: Attachment to add
    /// - Returns: Modified steps with attachment added to last failed step
    internal static func attachToLastFailedStep(steps: [StepResult], attachment: Attachment) -> [StepResult] {
        var modifiedSteps = steps

        if let failedStepIndex = findLastFailedStepIndex(in: modifiedSteps) {
            var failedStep = modifiedSteps[failedStepIndex.index]

            if let nestedSteps = failedStep.steps,
               let _ = findLastFailedStepIndex(in: nestedSteps) {

                failedStep.steps = attachToLastFailedStep(steps: nestedSteps, attachment: attachment)
            } else {
                var stepAttachments = failedStep.attachments ?? []
                stepAttachments.append(attachment)
                failedStep.attachments = stepAttachments
            }

            modifiedSteps[failedStepIndex.index] = failedStep
        }

        return modifiedSteps
    }

    /// Finds the index of the last failed step
    private static func findLastFailedStepIndex(in steps: [StepResult]) -> (index: Int, step: StepResult)? {
        for (index, step) in steps.enumerated().reversed() {
            if step.status == .failed || step.status == .broken {
                return (index, step)
            }

            if let nestedSteps = step.steps,
               let _ = findLastFailedStepIndex(in: nestedSteps) {
                return (index, step)
            }
        }
        return nil
    }

    /// Attaches attachment to the deepest step as fallback
    internal static func attachToDeepestStep(steps: [StepResult], attachment: Attachment) -> [StepResult] {
        guard let lastIndex = steps.indices.last else { return steps }

        var modifiedSteps = steps
        var lastStep = modifiedSteps[lastIndex]

        if let nestedSteps = lastStep.steps, !nestedSteps.isEmpty {
            lastStep.steps = attachToDeepestStep(steps: nestedSteps, attachment: attachment)
        } else {
            var stepAttachments = lastStep.attachments ?? []
            stepAttachments.append(attachment)
            lastStep.attachments = stepAttachments
        }

        modifiedSteps[lastIndex] = lastStep
        return modifiedSteps
    }
}
