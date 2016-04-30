//
//  ForceTouchAssignmentsDetailViewController.swift
//  GradeCheck
//
//  Created by Ivan Chau on 4/28/16.
//  Copyright © 2016 Ivan Chau. All rights reserved.
//

import UIKit
import EventKit
class ForceTouchAssignmentsDetailViewController: UIViewController {

    @IBOutlet weak var assignmentTitle : UILabel!
    @IBOutlet weak var detailTitle : UILabel?
    @IBOutlet weak var categoryTitle : UILabel!
    @IBOutlet weak var courseTitle : UILabel!
    @IBOutlet weak var dueDate : UILabel!
    @IBOutlet weak var percentage : AssignmentScoreView!
    @IBOutlet weak var gradeI : UILabel!
    @IBOutlet weak var gradeF : UILabel!
    @IBOutlet weak var teacherName : UILabel!
    @IBOutlet weak var close : UIButton!
    @IBOutlet weak var calendar : UIButton!
    var assignment : NSDictionary!
    var calendarReady : Bool = true;
    var assignorNo : Bool = false;
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        print(assignment)
        if(calendarReady){
            let cal = UIImage(named: "calendar.png")?.imageWithRenderingMode(.AlwaysTemplate)
            self.calendar.setImage(cal, forState: .Normal)
            self.calendar.setImage(cal, forState: .Selected)
            self.calendar.tintColor = UIColor(red: 250/255.0, green: 251/255.0, blue: 250/255.0, alpha: 1.0)
        }else{
            let cal = UIImage(named:"check.png")
            self.calendar.setImage(cal, forState: .Normal)
            self.calendar.setImage(cal, forState: .Selected)
        }
        assignmentTitle.text = assignment["assignment"]!["title"] as? String
        if(assignment["assignment"]!["details"] != nil){
            detailTitle!.text = assignment["assignment"]!["details"] as? String
        }
        categoryTitle.text = assignment["category"] as? String
        courseTitle.text = assignment["course"] as? String
        gradeI.text = assignment["grade"] as? String
        gradeF.text = assignment["gradeMax"] as? String
        dueDate.text = assignment["stringDate"] as? String
        teacherName.text = assignment["teacher"] as? String
        percentage.layer.cornerRadius = 0.5 * percentage.bounds.height;
        var g = assignment["percent"] as? String
        if(g!.containsString("%")){
            percentage.score.text = g!;
            g = String(g!.characters.dropLast());
            switch Double(g!)!{
            case 0..<50:
                percentage.backgroundColor = UIColor.blackColor()
            case 51..<75 :
                percentage.backgroundColor = UIColor.redColor()
            case 76..<85 :
                percentage.backgroundColor = UIColor.yellowColor()
            case 86..<110 :
                percentage.backgroundColor = UIColor(red: 0.1574, green: 0.6298, blue: 0.2128, alpha: 1.0);
            default :
                percentage.backgroundColor = UIColor.purpleColor()
            }
        }else{
            percentage.backgroundColor = UIColor.blackColor()
            percentage.score.text = "--"
        }
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func dismiss(){
        CellAnimation.growAndShrink(percentage)
        if(assignorNo == true){
            let vc = self.presentingViewController as! DetailGradeViewController
            vc.ridOfBlur()
            self.dismissViewControllerAnimated(true, completion: nil)
        }else{
            let vc = self.presentingViewController as! GradeViewController
            let av = vc.selectedViewController as! AssignmentsTableViewController
            av.ridOfBlur()
            self.dismissViewControllerAnimated(true){
                
            }
        }
    }
    func addtoCalendarClicked() {
        CellAnimation.growAndShrink(percentage)
        if(calendarReady){
            let eventStore = EKEventStore()
            
            eventStore.requestAccessToEntityType( EKEntityType.Event, completion:{(granted, error) in
                
                if (granted) && (error == nil) {
                    print("granted \(granted)")
                    print("error \(error)")
                    var localSource : EKSource = EKSource()
                    for source in eventStore.sources {
                        if (source.sourceType == EKSourceType.CalDAV &&
                            source.title == "iCloud")
                        {
                            localSource = source;
                            break;
                        }
                    }
                    
                    if (localSource.title != "iCloud")
                    {
                        for source in eventStore.sources
                        {
                            if (source.sourceType == .Local)
                            {
                                localSource = source;
                                break;
                            }
                        }
                    }
                    var calendar : EKCalendar;
                        if (NSUserDefaults.standardUserDefaults().objectForKey("calendarIdentifier") == nil || (NSUserDefaults.standardUserDefaults().objectForKey("calendarIdentifier") as! String) == ""){
                            calendar = EKCalendar(forEntityType: EKEntityType.Event, eventStore: eventStore)
                            calendar.title = "GradeCheck"
                            calendar.CGColor = UIColor(red: 0.1574, green: 0.6298, blue: 0.2128, alpha: 1.0).CGColor
                            calendar.source = localSource
                            do{
                                try eventStore.saveCalendar(calendar, commit: true)
                            }catch let error as NSError{
                                let failureAlert = UIAlertController(title: "Error", message: "Failed to create calendar." + error.localizedDescription, preferredStyle: .Alert)
                                let action = UIAlertAction(title: "Darn.", style: .Default, handler: nil)
                                failureAlert.addAction(action)
                                self.presentViewController(failureAlert, animated: true, completion: nil)
                            }
                            NSUserDefaults.standardUserDefaults().setObject(calendar.calendarIdentifier, forKey: "calendarIdentifier")
                        }else{
                            if let c = eventStore.calendarWithIdentifier(NSUserDefaults.standardUserDefaults().objectForKey("calendarIdentifier") as! String) {
                                calendar = c
                            }else{
                                calendar = eventStore.defaultCalendarForNewEvents
                            }
                        }
                    
                    let event = EKEvent(eventStore: eventStore)
                    
                    event.title = self.assignmentTitle.text!
                    let dateFormatter = NSDateFormatter()
                    dateFormatter.setLocalizedDateFormatFromTemplate("MM/dd/yy")
                    let date1 = dateFormatter.dateFromString(self.dueDate.text!);
                    let cal: NSCalendar! = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
                    let startDate = cal.dateBySettingHour(7, minute: 20, second: 0, ofDate: date1!, options: .MatchFirst)
                    event.startDate = startDate!
                    event.endDate = (startDate?.dateByAddingTimeInterval(60*60))!;
                    event.notes = self.detailTitle!.text!
                    event.calendar = calendar
                    let alarm : EKAlarm = EKAlarm(relativeOffset: -60*60*15)
                    let secondAlarm : EKAlarm = EKAlarm(relativeOffset: -60*60*39)
                    event.alarms = [alarm, secondAlarm]
                    
                    var event_id = ""
                    do{
                        try eventStore.saveEvent(event, span: .ThisEvent)
                        event_id = event.eventIdentifier
                    }
                    catch let error as NSError {
                        print("json error: \(error.localizedDescription)")
                    }
                    
                    if(event_id != ""){
                        dispatch_async(dispatch_get_main_queue(), {
                            let alertString = self.assignmentTitle.text! + " has been added to your calendar!"
                            let alert = UIAlertController(title: "Added to Calendar" , message: alertString, preferredStyle: .Alert);
                            let cool = UIAlertAction(title: "Cool!", style: .Default, handler: nil)
                            alert.addAction(cool)
                            self.presentViewController(alert, animated: true, completion: nil)
                            print("event added !")
                            
                        })
                        
                    }
                }
            })
        }
    }
    override func previewActionItems() -> [UIPreviewActionItem] {
        if(calendarReady){
            let addToCalendar = UIPreviewAction(title: "Add to Calendar", style: .Default) { (action: UIPreviewAction, vc : UIViewController) in
                print("Handler executing");
                self.addtoCalendarClicked()
            }
            return [addToCalendar]
        }else{
            return [];
        }
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
}