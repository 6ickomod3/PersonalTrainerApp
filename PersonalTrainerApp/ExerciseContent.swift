import Foundation

struct StaticGuideItem: Identifiable {
    var id = UUID()
    var name: String
    var duration: String // e.g. "30s" or "15 reps"
    var icon: String // SF Symbol
    var instruction: String
}

struct MuscleGroupContent {
    static func warmups(for groupName: String) -> [StaticGuideItem] {
        switch groupName.lowercased() {
        case "chest":
            return [
                StaticGuideItem(name: "Arm Circles", duration: "30s", icon: "arrow.triangle.2.circlepath", instruction: "Stand with feet shoulder-width apart. Extend arms to the side and make small circles, gradually increasing size. Reverse direction halfway through."),
                StaticGuideItem(name: "Band Pull-Aparts", duration: "15 reps", icon: "figure.arms.open", instruction: "Hold a resistance band with both hands in front of you. Pull the band apart by squeezing your shoulder blades together until the band touches your chest. Return slowly."),
                StaticGuideItem(name: "Push-Ups (Light)", duration: "10 reps", icon: "figure.strengthtraining.traditional", instruction: "Perform standard push-ups or on knees. Focus on full range of motion to warm up the chest and triceps. Do not go to failure.")
            ]
        case "back":
            return [
                StaticGuideItem(name: "Cat-Cow Stretch", duration: "1 min", icon: "cat", instruction: "Start on hands and knees. Inhale and arch your back (Cow), looking up. Exhale and round your spine (Cat), tucking your chin. Repeat slowly."),
                StaticGuideItem(name: "Band Face Pulls", duration: "15 reps", icon: "figure.pull", instruction: "Attach a band to a high anchor. Pull usage towards your face, keeping elbows high and rotating externally. Squeeze your rear delts."),
                StaticGuideItem(name: "Thoracic Rotation", duration: "10 reps", icon: "rotate.3d", instruction: "On hands and knees, place one hand behind your head. Rotate your elbow down to the opposite hand, then open up towards the ceiling.")
            ]
        case "leg":
            return [
                StaticGuideItem(name: "Leg Swings", duration: "15/side", icon: "figure.socialdance", instruction: "Hold onto a wall for support. Swing one leg forward and backward in a controlled motion to loosen up the hips and hamstrings."),
                StaticGuideItem(name: "Bodyweight Squats", duration: "15 reps", icon: "figure.walk", instruction: "Stand feet shoulder-width apart. Lower your hips back and down as if sitting in a chair. Keep chest up. Stand back up squeezing glutes."),
                StaticGuideItem(name: "Hip Circles", duration: "30s", icon: "circle.grid.2x2", instruction: "Stand on one leg (support if needed). Lift the other knee and rotate the hip in a large circle motion. Switch directions.")
            ]
        case "shoulder":
            return [
                StaticGuideItem(name: "Arm Cross Swing", duration: "30s", icon: "figure.arms.open", instruction: "Swing your arms across your chest, alternating which arm is on top. Open wide to stretch the chest, cross to stretch rear delts."),
                StaticGuideItem(name: "Halo Rotations", duration: "10 reps", icon: "circle.dashed", instruction: "Hold a light weight or plate. Circle it around your head, keeping it close. Focus on shoulder mobility."),
                StaticGuideItem(name: "Shoulder Dislocates", duration: "10 reps", icon: "arrow.left.and.right", instruction: "Hold a stick or band with wide grip. Bring it over your head and behind your back with straight arms. Adjust grip width as needed.")
            ]
        case "arm":
            return [
                StaticGuideItem(name: "Wrist Circles", duration: "30s", icon: "hand.raised.fingers.spread", instruction: "Clasp hands together and rotate wrists in circles. Then stretch wrists by pulling fingers back gently."),
                StaticGuideItem(name: "Empty Bar Curls", duration: "20 reps", icon: "dumbbell", instruction: "Perform bicep curls with just the barbell or very light weight to get blood flowing into the biceps."),
                StaticGuideItem(name: "Tricep Overhead", duration: "30s", icon: "figure.arms.open", instruction: "Reach one arm overhead and bend the elbow. Use the other hand to gently push the elbow down to stretch the tricep.")
            ]
        default:
            return [
                StaticGuideItem(name: "Jumping Jacks", duration: "1 min", icon: "figure.jumprope", instruction: "Jump feet wide while bringing arms overhead. Jump feet together bringing arms down. Increases heart rate."),
                StaticGuideItem(name: "Arm Circles", duration: "30s", icon: "arrow.triangle.2.circlepath", instruction: "Simple arm circles to warm up the shoulder girdle.")
            ]
        }
    }
    
    static func stretches(for groupName: String) -> [StaticGuideItem] {
        switch groupName.lowercased() {
        case "chest":
            return [
                StaticGuideItem(name: "Doorway Stretch", duration: "45s", icon: "house.fill", instruction: "Place forearms on a doorframe at 90 degrees. Step through gently to stretch the chest muscles."),
                StaticGuideItem(name: "Hands Clasp Behind", duration: "30s", icon: "figure.stand", instruction: "Clasp hands behind your back and straighten arms. Lift hands away from your back to open the chest.")
            ]
        case "back":
            return [
                StaticGuideItem(name: "Child's Pose", duration: "1 min", icon: "figure.child.neck", instruction: "Kneel and sit back on your heels. Reach arms forward on the floor and lower your head. Stretches the back and lats."),
                StaticGuideItem(name: "Dead Hang", duration: "30s", icon: "figure.arms.open", instruction: "Hang freely from a pull-up bar. Relax your shoulders and let gravity decompress your spine."),
                StaticGuideItem(name: "Cobra Stretch", duration: "45s", icon: "waveform.path.ecg", instruction: "Lie on stomach. Push up with hands to lift chest off the floor, keeping hips down. Stretches abdominals and lower back.")
            ]
        case "leg":
            return [
                StaticGuideItem(name: "Hamstring Stretch", duration: "45s", icon: "figure.yoga", instruction: "Sit with one leg extended. Reach towards the toes of the extended leg. Keep back straight."),
                StaticGuideItem(name: "Quad Stretch", duration: "45s", icon: "figure.walk", instruction: "Stand on one leg. Pull the other foot behind you towards your glutes. Keep knees together."),
                StaticGuideItem(name: "Pigeon Pose", duration: "1 min", icon: "figure.seated.side.left", instruction: "Bring one knee forward and extend the other leg back. Lower your hips towards the floor to stretch the glutes.")
            ]
        case "shoulder":
            return [
                StaticGuideItem(name: "Cross Body Stretch", duration: "45s", icon: "figure.stand", instruction: "Pull one arm across your chest with the other arm. Stretches the rear deltoid and rotator cuff."),
                StaticGuideItem(name: "Neck Tilt", duration: "30s/side", icon: "ear", instruction: "Gently tilt head towards one shoulder. Use hand to apply very light pressure for a deeper stretch.")
            ]
        case "arm":
            return [
                StaticGuideItem(name: "Wrist Flexor Stretch", duration: "30s", icon: "hand.point.up.left", instruction: "Extend arm with palm facing up. Pull fingers down and back with the other hand."),
                StaticGuideItem(name: "Overhead Tricep", duration: "45s", icon: "figure.arms.open", instruction: "Reach arm overhead, bend elbow. Gently pull elbow behind head to stretch the tricep.")
            ]
        default:
            return [
                StaticGuideItem(name: "Forward Fold", duration: "1 min", icon: "figure.yoga", instruction: "Stand and hinge at hips to reach towards your toes. Let head hang heavy to release the spine."),
                StaticGuideItem(name: "Deep Squat Hold", duration: "45s", icon: "figure.flexibility", instruction: "Sit in a deep squat position. Push knees out with elbows. Stretches hips and ankles.")
            ]
        }
    }
}
