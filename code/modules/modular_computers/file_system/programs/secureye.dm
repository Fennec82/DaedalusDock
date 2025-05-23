#define DEFAULT_MAP_SIZE 15

/datum/computer_file/program/secureye
	filename = "secureye"
	filedesc = "SecurEye"
	category = PROGRAM_CATEGORY_MISC
	ui_header = "borg_mon.gif"
	program_icon_state = "generic"
	extended_desc = "This program allows access to standard security camera networks."
	requires_ntnet = TRUE
	transfer_access = list(ACCESS_SECURITY)
	usage_flags = PROGRAM_CONSOLE | PROGRAM_LAPTOP
	size = 5
	tgui_id = "NtosSecurEye"
	program_icon = "eye"

	var/list/network = list("ss13")
	/// Weakref to the active camera
	var/datum/weakref/camera_ref
	/// The turf where the camera was last updated.
	var/turf/last_camera_turf
	var/list/concurrent_users = list()

	// Stuff needed to render the map
	var/atom/movable/screen/map_view/byondui/camera/cam_screen


/datum/computer_file/program/secureye/New()
	. = ..()

	// Convert networks to lowercase
	for(var/i in network)
		network -= i
		network += lowertext(i)

	var/map_name = "camera_console_[REF(src)]_map"
	// Initialize map objects
	cam_screen = new()
	cam_screen.generate_view(map_name)

/datum/computer_file/program/secureye/Destroy()
	QDEL_NULL(cam_screen)
	return ..()

/datum/computer_file/program/secureye/ui_interact(mob/user, datum/tgui/ui)
	// Update UI
	ui = SStgui.try_update_ui(user, src, ui)

	// Update the camera, showing static if necessary and updating data if the location has moved.
	update_active_camera_screen()

	var/user_ref = REF(user)
	var/is_living = isliving(user)
	// Ghosts shouldn't count towards concurrent users, which produces
	// an audible terminal_on click.
	if(is_living)
		concurrent_users += user_ref

	// Register map objects
	cam_screen.render_to_tgui(user.client, ui.window)

/datum/computer_file/program/secureye/ui_status(mob/user)
	. = ..()
	if(. == UI_DISABLED)
		return UI_CLOSE
	return .

/datum/computer_file/program/secureye/ui_data()
	var/list/data = get_header_data()
	data["network"] = network
	data["activeCamera"] = null
	var/obj/machinery/camera/active_camera = camera_ref?.resolve()
	if(active_camera)
		data["activeCamera"] = list(
			name = active_camera.c_tag,
			status = active_camera.status,
		)
	return data

/datum/computer_file/program/secureye/ui_static_data()
	var/list/data = list()
	data["mapRef"] = cam_screen.assigned_map
	var/list/cameras = get_available_cameras()
	data["cameras"] = list()
	for(var/i in cameras)
		var/obj/machinery/camera/C = cameras[i]
		data["cameras"] += list(list(
			name = C.c_tag,
		))

	return data

/datum/computer_file/program/secureye/ui_act(action, params)
	. = ..()
	if(.)
		return

	if(action == "switch_camera")
		var/c_tag = format_text(params["name"])
		var/list/cameras = get_available_cameras()
		var/obj/machinery/camera/selected_camera = cameras[c_tag]
		camera_ref = WEAKREF(selected_camera)
		playsound(src, get_sfx(SFX_TERMINAL_TYPE), 25, FALSE)

		if(!selected_camera)
			return TRUE

		update_active_camera_screen()

		return TRUE

/datum/computer_file/program/secureye/ui_close(mob/user)
	. = ..()
	var/user_ref = REF(user)
	var/is_living = isliving(user)
	// Living creature or not, we remove you anyway.
	concurrent_users -= user_ref
	// Unregister map objects
	cam_screen?.hide_from_client(user.client)
	// Turn off the console
	if(length(concurrent_users) == 0 && is_living)
		camera_ref = null
		playsound(src, 'sound/machines/terminal_off.ogg', 25, FALSE)

/datum/computer_file/program/secureye/proc/update_active_camera_screen()
	var/obj/machinery/camera/active_camera = camera_ref?.resolve()
	// Show static if can't use the camera
	if(!active_camera?.can_use())
		cam_screen.show_camera_static()
		return

	var/list/visible_turfs = list()

	// Is this camera located in or attached to a living thing? If so, assume the camera's loc is the living thing.
	var/cam_location = isliving(active_camera.loc) ? active_camera.loc : active_camera

	// If we're not forcing an update for some reason and the cameras are in the same location,
	// we don't need to update anything.
	// Most security cameras will end here as they're not moving.
	var/newturf = get_turf(cam_location)
	if(last_camera_turf == newturf)
		return

	// Cameras that get here are moving, and are likely attached to some moving atom such as cyborgs.
	last_camera_turf = get_turf(cam_location)

	var/list/visible_things = active_camera.isXRay() ? range(active_camera.view_range, cam_location) : view(active_camera.view_range, cam_location)

	for(var/turf/visible_turf in visible_things)
		visible_turfs += visible_turf

	var/list/bbox = get_bbox_of_atoms(visible_turfs)
	var/size_x = bbox[3] - bbox[1] + 1
	var/size_y = bbox[4] - bbox[2] + 1

	cam_screen.show_camera(visible_turfs, size_x, size_y)

// Returns the list of cameras accessible from this computer
/datum/computer_file/program/secureye/proc/get_available_cameras()
	var/list/L = list()
	for (var/obj/machinery/camera/cam in GLOB.cameranet.cameras)
		if(!is_station_level(cam.z))//Only show station cameras.
			continue
		L.Add(cam)
	var/list/camlist = list()
	for(var/obj/machinery/camera/cam in L)
		if(!cam.network)
			stack_trace("Camera in a cameranet has no camera network")
			continue
		if(!(islist(cam.network)))
			stack_trace("Camera in a cameranet has a non-list camera network")
			continue
		var/list/tempnetwork = cam.network & network
		if(tempnetwork.len)
			camlist["[cam.c_tag]"] = cam
	return camlist
