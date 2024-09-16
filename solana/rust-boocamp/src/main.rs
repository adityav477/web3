// fn main() {
    // let x: i32 = -132;
    // let z: f32 = 3233.23;
    // let y: u32 = 2343;
    //
    // print!("x: {}, y: {}, z: {} ",x,y,z);

    //Strings quite hard in rust 
    //     let string: String = String::from("hello world");
    //
    //     let char1 = string.chars().nth(0);
    //     // match  char1 {
    //     //     Some(c) => print!("{}",c),
    //     //     None => print!("No character was found")
    //     // }
    // print!("first character is {}",char1.unwrap());

    //For Loops 
    // for i: i8 in 0..10{
    //     print!("{}",i);
    // }
// }

fn main() {
    let sentence = String::from("this is a sentence ");
    let first_word = get_first_word(sentence);
}

fn get_first_word(sentence: String) -> String {
    let mut ans = String::from("");

    for char in sentence.chars() {
        ans.push_str(string: char.to_string().as_str());
        if char == ' ' {
            break;
        }
    }

    return  ans;
}
