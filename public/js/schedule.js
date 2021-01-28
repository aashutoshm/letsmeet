// Gets the localized string
function getLocalizedString(key) {
    var keyArr = key.split(".")
    var translated = I18n

    // Search current language for the key
    try {
        keyArr.forEach(function (k) {
            translated = translated[k]
        })
    } catch (e) {
        // Key is missing in selected language so default to english
        translated = undefined;
    }


    // If key is not found, search the fallback language for the key
    if (translated === null || translated === undefined) {
        translated = I18nFallback

        keyArr.forEach(function (k) {
            translated = translated[k]
        })
    }

    return translated
}

function generateAccessCode() {
    const accessCodeLength = 6
    var validCharacters = "0123456789"
    var accessCode = ""

    for (var i = 0; i < accessCodeLength; i++) {
        accessCode += validCharacters.charAt(Math.floor(Math.random() * validCharacters.length));
    }

    $("#create-room-access-code").text(getLocalizedString("modal.create_room.access_code") + ": " + accessCode)
    $("#room_access_code").val(accessCode)
}

function ResetAccessCode() {
    $("#create-room-access-code").text(getLocalizedString("modal.create_room.access_code_placeholder"))
    $("#room_access_code").val(null)
}

var eventBus = new Vue();

new Vue({
    el: '#schedule-meeting',
    data: {
        id: null,
        title: '',
        start_date: '',
        end_date: '',
        start_time: '',
        end_time: '',
        all_day: false,
        repeat_weekly: false,
        repeat_day: 0,
        mute_video: false,
        mute_audio: false,
        record_meeting: false,
        description: '',
        event_tags: [],
        notification_type: 'Email',
        notification_minutes: 10,
        guests: [],
        guest_name: '',
        guest_permissions: [],
        everyone_as_admin: false,
        modify_meeting: false,
        invite_others: false,
        see_guest_list: false,
        timezones: [],
        selected_tz_name: 'Asia/Calcutta',
        room_uid: null
    },
    mounted: function () {
        eventBus.$on('SCHEDULE_CLICKED', (event) => {
            this.id = event.id
            axios.get(`/schedules/${this.id}`)
                .then(res => res.data)
                .then(data => {
                    this.title = data.title
                    this.start_date = data.start_date
                    this.end_date = data.end_date
                    this.start_time = data.start_time
                    this.end_time = data.end_time
                    this.all_day = data.all_day
                    this.repeat_weekly = data.repeat_weekly
                    this.repeat_day = data.repeat_day
                    this.mute_audio = data.mute_audio
                    this.mute_video = data.mute_video
                    this.record_meeting = data.record_meeting
                    this.description = data.description
                    this.event_tags = []
                    if (data.event_tags) {
                        var a = data.events_tag.split(',')
                        a.forEach(x => {
                            this.event_tags.push(x)
                        })
                    }
                    this.notification_type = data.notification_type
                    this.notification_minutes = data.notification_minutes
                    this.selected_tz_name = data.timezone
                    this.guests = []
                    data.guests.forEach(g => {
                        this.guests.push(g.username)
                    })

                    data.guest_permissions.forEach(gp => {
                        switch (gp.name) {
                            case "everyone_as_admin":
                                this.everyone_as_admin = gp.value
                                break
                            case "modify_meeting":
                                this.modify_meeting = gp.value
                                break
                            case "invite_others":
                                this.invite_others = gp.value
                                break
                            case "see_guest_list":
                                this.see_guest_list = gp.value
                                break
                            default:
                                console.log(gp.name)
                        }
                    })
                    this.room_uid = data.room.uid

                    $('#schedule-meeting-modal').modal('show');
                }).catch(error => console.error(error))
        })

        eventBus.$on('CALENDAR_CLICKED', (selectedDateString) => {
            var selectedDate = new Date(selectedDateString)
            this.start_date = selectedDateString
            this.id = null
            this.repeat_day = selectedDate.getDay();
        })

        eventBus.$on('FULL_CALENDAR_CLICKED', (date) => {
            this.id = null
            this.start_date = this.getOnlyDate(date)
            this.start_time = this.getOnlyTime(date)
            this.repeat_day = date.getDay();
        })

        const getTimezoneList = moment.tz.names().map(t => {
            return {
                name: `(GMT${moment.tz(t).format('Z')}) ${t}`,
                value: t
            }
        });
        this.timezones = getTimezoneList.sort(this.sortByZone)
    },
    methods: {
        sortByZone(a, b) {
            let [ahh, amm] = a.name.split("GMT")[1].split(")")[0].split(":");
            let [bhh, bmm] = b.name.split("GMT")[1].split(")")[0].split(":");
            return (+ahh * 60 + amm) - (+bhh * 60 + bmm)
        },
        handleSubmit() {
            let authenticity_token = $('#authenticity_token').val();

            if (this.id) {
                axios.post(`/schedules/${this.id}`, {
                    authenticity_token: authenticity_token,
                    title: this.title,
                    start_date: this.start_date,
                    end_date: this.end_date,
                    start_time: this.start_time,
                    end_time: this.end_time,
                    all_day: this.all_day,
                    repeat_weekly: this.repeat_weekly,
                    repeat_day: this.repeat_day,
                    mute_video: this.mute_video,
                    mute_audio: this.mute_audio,
                    record_meeting: this.record_meeting,
                    description: this.description,
                    event_tags: this.event_tags,
                    notification_type: this.notification_type,
                    notification_minutes: this.notification_minutes,
                    guests: this.guests,
                    guest_permissions: {
                        everyone_as_admin: this.everyone_as_admin,
                        modify_meeting: this.modify_meeting,
                        invite_others: this.invite_others,
                        see_guest_list: this.see_guest_list
                    },
                    timezone: this.selected_tz_name,
                })
                    .then(res => {
                        window.location.reload();
                    })
                    .catch(error => console.error(error))
            } else {
                axios.post('/schedules/store', {
                    authenticity_token: authenticity_token,
                    title: this.title,
                    start_date: this.start_date,
                    end_date: this.end_date,
                    start_time: this.start_time,
                    end_time: this.end_time,
                    all_day: this.all_day,
                    repeat_weekly: this.repeat_weekly,
                    repeat_day: this.repeat_day,
                    mute_video: this.mute_video,
                    mute_audio: this.mute_audio,
                    record_meeting: this.record_meeting,
                    description: this.description,
                    event_tags: this.event_tags,
                    notification_type: this.notification_type,
                    notification_minutes: this.notification_minutes,
                    guests: this.guests,
                    guest_permissions: {
                        everyone_as_admin: this.everyone_as_admin,
                        modify_meeting: this.modify_meeting,
                        invite_others: this.invite_others,
                        see_guest_list: this.see_guest_list
                    },
                    timezone: this.selected_tz_name,
                })
                    .then(res => {
                        window.location.reload();
                    })
                    .catch(error => console.error(error))
            }
        },
        handleAddGuest() {
            if (this.guest_name) {
                this.guests.push(this.guest_name);
                this.guest_name = ''
            }
        },
        addGuest(e) {
            if (e.keyCode == 13) {
                e.preventDefault()
                if (this.guest_name) {
                    this.guests.push(this.guest_name);
                    this.guest_name = ''
                }
            }
        },
        removeGuest(index) {
            this.guests.splice(index, 1)
        },
        getOnlyDate(date) {
            var month = '' + (date.getMonth() + 1),
                day = '' + date.getDate(),
                year = date.getFullYear();

            if (month.length < 2)
                month = '0' + month;
            if (day.length < 2)
                day = '0' + day;

            return [year, month, day].join('-');
        },
        getOnlyTime(date) {
            var hours = '' + date.getHours(),
                minutes = '' + date.getMinutes();

            if (hours.length < 2)
                hours = '0' + hours;
            if (minutes.length < 2)
                minutes = '0' + minutes;

            return [hours, minutes].join(':');
        },
        startMeeting() {
            let authenticity_token = $('#authenticity_token').val();
            var form = document.createElement("form")
            var tokenEl = document.createElement("input")

            form.method = "POST"
            form.action = `/${this.room_uid}/start`

            tokenEl.value = authenticity_token
            tokenEl.name = "authenticity_token"

            form.appendChild(tokenEl);
            document.body.appendChild(form)
            form.submit();
        }
    }
})

new Vue({
    el: '#upcoming-events',
    data: {
        schedules: []
    },
    mounted() {
        axios.get('/schedules/upcoming')
            .then(res => res.data)
            .then(data => {
                this.schedules = data
            })
            .catch(error => console.error(error))
    },
    methods: {
        getEventTags(tag_string) {
            return tag_string.split(",")
        },
        getFullDate(dateString) {
            return new Date(dateString).toDateString();
        },
        getFullName(user) {
            if (user.first_name || user.last_name) {
                return user.first_name + ' ' + user.last_name
            } else {
                return user.name
            }
        }
    }
})

var calendar_el = document.getElementById('tiny-calendar')

if (calendar_el) {
    const tinyCalendar = new TavoCalendar(calendar_el);
    calendar_el.addEventListener('calendar-select', (e) => {
        eventBus.$emit('CALENDAR_CLICKED', tinyCalendar.getSelected())
        $('#schedule-meeting-modal').modal('show');
    })
}

document.addEventListener('DOMContentLoaded', function () {
    var calendarEl = document.getElementById('calendar');
    if (calendarEl) {
        var calendar = new FullCalendar.Calendar(calendarEl, {
            initialView: 'dayGridMonth',
            themeSystem: 'bootstrap',
            headerToolbar: {
                left: 'prev,next today',
                center: 'title',
                right: 'dayGridMonth,timeGridWeek,timeGridDay,listMonth'
            },
            events: {
                url: '/schedules/ajax',
                failure: function () {
                    console.log('failed')
                }
            },
            eventClick: function (info) {
                eventBus.$emit('SCHEDULE_CLICKED', info.event)
            },
            dateClick: function (info) {
                eventBus.$emit('FULL_CALENDAR_CLICKED', info.date)
                $('#schedule-meeting-modal').modal('show');
            }
        });
        calendar.render();
    }
});